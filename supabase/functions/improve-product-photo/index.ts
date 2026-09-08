import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { InferenceClient } from "npm:@huggingface/inference@^4.13.28";
import { imageSize as sizeOf } from "npm:image-size@^2.0.2";
import { decode as decodeJpeg, encode as encodeJpeg } from "npm:@jsquash/jpeg@^1.6.0";
import { decode as decodePng, encode as encodePng } from "npm:@jsquash/png@^3.1.1";
import { decode as decodeWebp, encode as encodeWebp } from "npm:@jsquash/webp@^1.5.0";
import resize from "npm:@jsquash/resize@^2.1.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

const STRICT_PRODUCT_EDIT_PROMPT =
  "Create a clean marketplace-ready product photo from this exact source image. " +
  "Preserve the product exactly as shown: same shape, proportions, colors, materials, " +
  "patterns, embroidery, printed text, logos, packaging details, quantity, and design. " +
  "Do not add or remove product features. " +
  "Only improve presentation: remove distracting background, use a clean neutral/light background, " +
  "center the product, improve lighting and clarity naturally, and keep realistic shadows where useful. " +
  "Do not stylize or redesign the product.";

function generateHexFilename(ext = "png"): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  const hex = Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return `${hex}.${ext}`;
}

function detectImageFormat(bytes: Uint8Array): { contentType: string; ext: string } {
  if (bytes.length >= 4 && bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47) {
    return { contentType: "image/png", ext: "png" };
  }
  if (bytes.length >= 3 && bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) {
    return { contentType: "image/jpeg", ext: "jpg" };
  }
  if (
    bytes.length >= 12 &&
    bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46 &&
    bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50
  ) {
    return { contentType: "image/webp", ext: "webp" };
  }
  return { contentType: "image/png", ext: "png" };
}

const MIN_DIMENSION_PIXELS = 256;
const MAX_RESIZE_DIMENSION = 4096;

export function calculateResizeDimensions(
  width: number,
  height: number,
  minDimension = MIN_DIMENSION_PIXELS,
): { targetWidth: number; targetHeight: number; needsResize: boolean } {
  if (width <= 0 || height <= 0 || (width >= minDimension && height >= minDimension)) {
    return { targetWidth: width, targetHeight: height, needsResize: false };
  }

  const scale = Math.max(minDimension / width, minDimension / height, 1);
  let targetWidth = Math.round(width * scale);
  let targetHeight = Math.round(height * scale);

  if (targetWidth < minDimension) targetWidth = minDimension;
  if (targetHeight < minDimension) targetHeight = minDimension;

  return { targetWidth, targetHeight, needsResize: true };
}

export async function resizeImageBytes(
  bytes: Uint8Array,
  mimeType: string,
  targetWidth: number,
  targetHeight: number,
): Promise<Uint8Array> {
  const arrayBuffer = bytes.buffer.slice(
    bytes.byteOffset,
    bytes.byteOffset + bytes.byteLength,
  ) as ArrayBuffer;

  let decoded: ImageData;
  if (mimeType === "image/png") {
    decoded = await decodePng(arrayBuffer);
  } else if (mimeType === "image/jpeg") {
    decoded = await decodeJpeg(arrayBuffer);
  } else if (mimeType === "image/webp") {
    decoded = await decodeWebp(arrayBuffer);
  } else {
    throw new Error(`Unsupported MIME type for resizing: ${mimeType}`);
  }

  const resized = await resize(decoded, { width: targetWidth, height: targetHeight });

  let encoded: ArrayBuffer;
  if (mimeType === "image/png") {
    encoded = await encodePng(resized);
  } else if (mimeType === "image/jpeg") {
    encoded = await encodeJpeg(resized);
  } else if (mimeType === "image/webp") {
    encoded = await encodeWebp(resized);
  } else {
    encoded = await encodePng(resized);
  }

  return new Uint8Array(encoded);
}

export async function handleImprovePhotoRequest(req: Request): Promise<Response> {
  // 1. CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // 2. Authentication extraction
  const authHeader = req.headers.get("Authorization") || req.headers.get("authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid authorization header" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return new Response(
      JSON.stringify({ error: "Supabase environment configuration missing" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Scoped client with user's JWT to verify identity
  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return new Response(
      JSON.stringify({ error: "Unauthorized: Invalid or expired session" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const userId = user.id;

  // 3. Input Validation
  let body: Record<string, unknown> | null = null;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON request body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { productId, sourceStoragePath } = body || {};

  if (!productId || typeof productId !== "string" || productId.trim().length === 0) {
    return new Response(JSON.stringify({ error: "Missing required field: productId" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (
    !sourceStoragePath ||
    typeof sourceStoragePath !== "string" ||
    sourceStoragePath.trim().length === 0
  ) {
    return new Response(
      JSON.stringify({ error: "Missing required field: sourceStoragePath" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const cleanSourcePath = sourceStoragePath.trim();
  const segments = cleanSourcePath.split("/");

  // Path invariant: <userId>/<productId>/<filename>
  if (segments.length !== 3 || segments.some((s) => s.trim().length === 0)) {
    return new Response(
      JSON.stringify({
        error: 'Invalid sourceStoragePath shape. Expected "<user>/<product>/<filename>"',
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  if (segments[0] !== userId) {
    return new Response(
      JSON.stringify({ error: "Forbidden: sourceStoragePath does not belong to authenticated user" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  if (segments[1] !== productId.trim()) {
    return new Response(
      JSON.stringify({ error: "Forbidden: sourceStoragePath does not belong to the specified product" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 4. Authorize Product Ownership and Image Membership
  // Use admin client if available, else userClient with RLS
  const dbClient = supabaseServiceKey
    ? createClient(supabaseUrl, supabaseServiceKey)
    : userClient;

  const { data: product, error: productError } = await dbClient
    .from("products")
    .select("id, producer_id, images")
    .eq("id", productId.trim())
    .single();

  if (productError || !product) {
    return new Response(JSON.stringify({ error: "Product not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (product.producer_id !== userId) {
    return new Response(
      JSON.stringify({ error: "Forbidden: You do not own this product" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const existingImages: string[] = Array.isArray(product.images) ? product.images : [];
  if (!existingImages.includes(cleanSourcePath)) {
    return new Response(
      JSON.stringify({
        error: "Forbidden: sourceStoragePath is not part of this product's images",
      }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 5. Retrieve Source Image from Storage
  const { data: fileBlob, error: downloadError } = await dbClient.storage
    .from("product-images")
    .download(cleanSourcePath);

  if (downloadError || !fileBlob) {
    return new Response(
      JSON.stringify({ error: `Failed to retrieve source image: ${downloadError?.message || "File not found"}` }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Validate size
  if (fileBlob.size > MAX_IMAGE_SIZE_BYTES) {
    return new Response(
      JSON.stringify({ error: `Source image exceeds 5 MB limit (${fileBlob.size} bytes)` }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Validate MIME type
  let mimeType = fileBlob.type?.toLowerCase() || "";
  if (!mimeType || mimeType === "application/octet-stream") {
    const ext = cleanSourcePath.split(".").pop()?.toLowerCase();
    if (ext === "jpg" || ext === "jpeg") mimeType = "image/jpeg";
    else if (ext === "png") mimeType = "image/png";
    else if (ext === "webp") mimeType = "image/webp";
  }

  if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
    return new Response(
      JSON.stringify({
        error: `Unsupported image format: "${mimeType}". Allowed types: JPEG, PNG, WebP.`,
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Read image bytes for dimension validation & optional temporary AI input resize
  const sourceArrayBuffer = await fileBlob.arrayBuffer();
  const sourceBytes = new Uint8Array(sourceArrayBuffer);

  let sourceWidth = 0;
  let sourceHeight = 0;
  try {
    const dimensions = sizeOf(sourceBytes);
    sourceWidth = dimensions.width || 0;
    sourceHeight = dimensions.height || 0;
  } catch (_) {
    // Fallback dimension extraction via decoder if header parsing fails
    try {
      const buf = sourceBytes.buffer.slice(
        sourceBytes.byteOffset,
        sourceBytes.byteOffset + sourceBytes.byteLength,
      ) as ArrayBuffer;
      let dec: ImageData | null = null;
      if (mimeType === "image/png") dec = await decodePng(buf);
      else if (mimeType === "image/jpeg") dec = await decodeJpeg(buf);
      else if (mimeType === "image/webp") dec = await decodeWebp(buf);
      if (dec) {
        sourceWidth = dec.width;
        sourceHeight = dec.height;
      }
    } catch (_) {
      // Fallback decode failure ignored; will proceed with zero or header dimensions
    }
  }

  console.log(`[improve-product-photo] source dimensions: ${sourceWidth}x${sourceHeight}`);

  let aiInputBlob: Blob = fileBlob;

  const resizePlan = calculateResizeDimensions(sourceWidth, sourceHeight, MIN_DIMENSION_PIXELS);
  if (resizePlan.needsResize) {
    if (resizePlan.targetWidth > MAX_RESIZE_DIMENSION || resizePlan.targetHeight > MAX_RESIZE_DIMENSION) {
      return new Response(
        JSON.stringify({
          error: "Source image aspect ratio or dimensions cannot be safely processed.",
          code: "HF_INVALID_DIMENSIONS",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[improve-product-photo] resized AI input: ${resizePlan.targetWidth}x${resizePlan.targetHeight}`);

    try {
      const resizedBytes = await resizeImageBytes(
        sourceBytes,
        mimeType,
        resizePlan.targetWidth,
        resizePlan.targetHeight,
      );
      aiInputBlob = new Blob([resizedBytes.buffer as ArrayBuffer], { type: mimeType });
    } catch (resizeErr: unknown) {
      const resizeMessage = resizeErr instanceof Error ? resizeErr.message : String(resizeErr);
      console.error(
        `[improve-product-photo] Failed to resize image below minimum dimensions: ${resizeMessage}`
      );
      return new Response(
        JSON.stringify({
          error: "Photo improvement service is temporarily unavailable. Please try again.",
          code: "HF_PROVIDER_ERROR",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }

  // 6. Hugging Face API Key check
  const hfToken = Deno.env.get("HF_TOKEN");
  if (!hfToken || hfToken.trim().length === 0) {
    return new Response(
      JSON.stringify({
        error: "AI enhancement service is not configured on the server. Please set HF_TOKEN.",
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 7. Call Hugging Face Inference Providers image-to-image API
  const model = Deno.env.get("HF_IMAGE_MODEL")?.trim() || "Qwen/Qwen-Image-Edit";

  let improvedBytes: Uint8Array;
  try {
    const hf = new InferenceClient(hfToken);

    const resultBlob: Blob = await hf.imageToImage({
      model,
      inputs: aiInputBlob,
      parameters: {
        prompt: STRICT_PRODUCT_EDIT_PROMPT,
      },
      provider: "auto",
    });

    if (!resultBlob || !(resultBlob instanceof Blob) || resultBlob.size === 0) {
      console.error("[improve-product-photo] Empty or malformed blob returned by Hugging Face provider");
      return new Response(
        JSON.stringify({
          error: "Photo improvement service is temporarily unavailable. Please try again.",
          code: "HF_PROVIDER_ERROR",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const arrayBuffer = await resultBlob.arrayBuffer();
    improvedBytes = new Uint8Array(arrayBuffer);

    if (improvedBytes.byteLength === 0) {
      console.error("[improve-product-photo] Provider returned 0 byte image buffer");
      return new Response(
        JSON.stringify({
          error: "Photo improvement service is temporarily unavailable. Please try again.",
          code: "HF_PROVIDER_ERROR",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (err: unknown) {
    const errorDetails = err as { httpResponse?: { status?: number }; status?: number; message?: string };
    console.error(
      `[improve-product-photo] Hugging Face inference error status=${errorDetails?.httpResponse?.status || errorDetails?.status || "unknown"}: ${errorDetails?.message || err}`
    );
    return new Response(
      JSON.stringify({
        error: "Photo improvement service is temporarily unavailable. Please try again.",
        code: "HF_PROVIDER_ERROR",
      }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 8. Store Improved Image as New Immutable Object
  const { contentType: outputContentType, ext: outputExt } = detectImageFormat(improvedBytes);
  const newFilename = generateHexFilename(outputExt);
  const improvedStoragePath = `${userId}/${productId.trim()}/${newFilename}`;

  const { error: uploadError } = await dbClient.storage
    .from("product-images")
    .upload(improvedStoragePath, improvedBytes, {
      contentType: outputContentType,
      upsert: false, // Strict: Do not overwrite
    });

  if (uploadError) {
    return new Response(
      JSON.stringify({ error: `Failed to save improved image: ${uploadError.message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 9. Return result to client
  // Notice: Canonical products.images in public.products is NOT modified here!
  // Client only replaces canonical path when user chooses "Use Improved Photo".
  return new Response(
    JSON.stringify({
      success: true,
      improvedStoragePath,
      sourceStoragePath: cleanSourcePath,
    }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
}

// Serve HTTP handler for Supabase Edge Functions runtime
serve(handleImprovePhotoRequest);
