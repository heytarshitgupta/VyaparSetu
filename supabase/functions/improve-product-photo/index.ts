import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

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
  let body: any;
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

  // 6. OpenAI API Key check
  const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
  if (!openaiApiKey || openaiApiKey.trim().length === 0) {
    return new Response(
      JSON.stringify({
        error: "AI enhancement service is not configured on the server. Please set OPENAI_API_KEY.",
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 7. Call OpenAI Image Edit API
  const model = Deno.env.get("OPENAI_IMAGE_MODEL")?.trim() || "gpt-image-2";

  const formData = new FormData();
  // Name the file cleanly with extension
  const sourceExt = mimeType === "image/jpeg" ? "jpg" : mimeType === "image/webp" ? "webp" : "png";
  formData.append("image", fileBlob, `source.${sourceExt}`);
  formData.append("prompt", STRICT_PRODUCT_EDIT_PROMPT);
  formData.append("model", model);
  formData.append("size", "1024x1024");
  formData.append("n", "1");
  formData.append("response_format", "b64_json");

  let improvedBytes: Uint8Array;
  try {
    const openaiRes = await fetch("https://api.openai.com/v1/images/edits", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiApiKey}`,
      },
      body: formData,
    });

    if (!openaiRes.ok) {
      const errText = await openaiRes.text();
      console.error(`[improve-product-photo] OpenAI API error status=${openaiRes.status}: ${errText}`);
      let sanitizedError = "AI image enhancement provider error";
      try {
        const errJson = JSON.parse(errText);
        if (errJson?.error?.message) {
          sanitizedError = errJson.error.message;
        }
      } catch (_) {}

      return new Response(
        JSON.stringify({ error: `AI provider error: ${sanitizedError}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const resultJson = await openaiRes.json();
    const item = resultJson?.data?.[0];

    if (item?.b64_json) {
      const binaryString = atob(item.b64_json);
      const len = binaryString.length;
      improvedBytes = new Uint8Array(len);
      for (let i = 0; i < len; i++) {
        improvedBytes[i] = binaryString.charCodeAt(i);
      }
    } else if (item?.url) {
      // Download generated image from provided URL
      const imgRes = await fetch(item.url);
      if (!imgRes.ok) {
        throw new Error("Failed to download generated image from provider URL");
      }
      const buffer = await imgRes.arrayBuffer();
      improvedBytes = new Uint8Array(buffer);
    } else {
      return new Response(
        JSON.stringify({ error: "Malformed response received from AI provider" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (err: any) {
    console.error(`[improve-product-photo] Exception calling AI provider: ${err?.message || err}`);
    return new Response(
      JSON.stringify({ error: `Failed to call AI provider: ${err?.message || "Unknown error"}` }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 8. Store Improved Image as New Immutable Object
  const newFilename = generateHexFilename("png");
  const improvedStoragePath = `${userId}/${productId.trim()}/${newFilename}`;

  const { error: uploadError } = await dbClient.storage
    .from("product-images")
    .upload(improvedStoragePath, improvedBytes, {
      contentType: "image/png",
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
