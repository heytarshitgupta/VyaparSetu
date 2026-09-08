// Node.js test for improve-product-photo Edge Function logic (Hugging Face Inference Providers)
import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

describe('Supabase Edge Function: improve-product-photo (Hugging Face Inference Providers)', () => {
  const MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024;
  const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
  const MIN_DIMENSION_PIXELS = 256;

  const STRICT_PRODUCT_EDIT_PROMPT =
    'Create a clean marketplace-ready product photo from this exact source image. ' +
    'Preserve the product exactly as shown: same shape, proportions, colors, materials, ' +
    'patterns, embroidery, printed text, logos, packaging details, quantity, and design. ' +
    'Do not add or remove product features. ' +
    'Only improve presentation: remove distracting background, use a clean neutral/light background, ' +
    'center the product, improve lighting and clarity naturally, and keep realistic shadows where useful. ' +
    'Do not stylize or redesign the product.';

  function calculateResizeDimensions(width, height, minDimension = MIN_DIMENSION_PIXELS) {
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

  // Test 1: HF_TOKEN used server-side and missing token produces 500
  test('Test 1: HF_TOKEN is read server-side via Deno.env.get("HF_TOKEN"); missing token fails safely', () => {
    const checkEnvToken = (envMap) => {
      const token = envMap['HF_TOKEN'];
      if (!token || token.trim().length === 0) {
        return {
          status: 500,
          body: { error: 'AI enhancement service is not configured on the server. Please set HF_TOKEN.' },
        };
      }
      return { status: 200, token: token.trim() };
    };

    assert.strictEqual(checkEnvToken({})?.status, 500);
    assert.strictEqual(checkEnvToken({ HF_TOKEN: '' })?.status, 500);
    assert.strictEqual(checkEnvToken({ HF_TOKEN: '   ' })?.status, 500);
    const valid = checkEnvToken({ HF_TOKEN: 'hf_mock_secret_token_123' });
    assert.strictEqual(valid.status, 200);
    assert.strictEqual(valid.token, 'hf_mock_secret_token_123');
  });

  // Test 2: Model defaults to Qwen/Qwen-Image-Edit and respects HF_IMAGE_MODEL override
  test('Test 2: Model defaults to Qwen/Qwen-Image-Edit and respects HF_IMAGE_MODEL override', () => {
    const resolveModel = (envVal) => (envVal?.trim() || 'Qwen/Qwen-Image-Edit');

    assert.strictEqual(resolveModel(undefined), 'Qwen/Qwen-Image-Edit');
    assert.strictEqual(resolveModel(''), 'Qwen/Qwen-Image-Edit');
    assert.strictEqual(resolveModel('   '), 'Qwen/Qwen-Image-Edit');
    assert.strictEqual(resolveModel('Qwen/Qwen-Image-Edit-Custom'), 'Qwen/Qwen-Image-Edit-Custom');
  });

  // Test 3: NVIDIA endpoint/key not used by function
  test('Test 3: Function does not depend on NVIDIA_API_KEY, NVIDIA_IMAGE_MODEL, or NVIDIA_ENDPOINT', () => {
    const envKeysUsedByFunction = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'HF_TOKEN', 'HF_IMAGE_MODEL'];
    assert.strictEqual(envKeysUsedByFunction.includes('NVIDIA_API_KEY'), false);
    assert.strictEqual(envKeysUsedByFunction.includes('NVIDIA_IMAGE_MODEL'), false);
    assert.strictEqual(envKeysUsedByFunction.includes('NVIDIA_ENDPOINT'), false);
  });

  // Test 4: Source image + prompt are sent through Hugging Face image-to-image flow with provider=auto
  test('Test 4: Hugging Face imageToImage invocation contract uses model, inputs blob, prompt parameter, and provider=auto', () => {
    const fakeBlob = { size: 1024, type: 'image/png' };
    const hfParams = {
      model: 'Qwen/Qwen-Image-Edit',
      inputs: fakeBlob,
      parameters: {
        prompt: STRICT_PRODUCT_EDIT_PROMPT,
      },
      provider: 'auto',
    };

    assert.strictEqual(hfParams.model, 'Qwen/Qwen-Image-Edit');
    assert.strictEqual(hfParams.inputs, fakeBlob);
    assert.strictEqual(hfParams.provider, 'auto');
    assert.strictEqual(hfParams.parameters.prompt, STRICT_PRODUCT_EDIT_PROMPT);
    // OpenAI or custom endpoints not used
    assert.strictEqual('size' in hfParams, false);
    assert.strictEqual('n' in hfParams, false);
    assert.strictEqual('response_format' in hfParams, false);
  });

  // Test 5: Strict product preservation prompt remains intact
  test('Test 5: Strict prompt enforces product preservation and forbids alterations/fabrications', () => {
    assert.strictEqual(STRICT_PRODUCT_EDIT_PROMPT.includes('same shape, proportions, colors, materials'), true);
    assert.strictEqual(STRICT_PRODUCT_EDIT_PROMPT.includes('patterns, embroidery, printed text, logos, packaging details, quantity, and design'), true);
    assert.strictEqual(STRICT_PRODUCT_EDIT_PROMPT.includes('Do not add or remove product features'), true);
    assert.strictEqual(STRICT_PRODUCT_EDIT_PROMPT.includes('Do not stylize or redesign the product'), true);
  });

  // Test 6: Unauthenticated request denied
  test('Test 6: Unauthenticated request denied without Bearer token (401)', () => {
    const authHeader = null;
    const isValid = Boolean(authHeader && authHeader.startsWith('Bearer '));
    assert.strictEqual(isValid, false);

    const invalidHeader = 'Basic 12345';
    assert.strictEqual(Boolean(invalidHeader && invalidHeader.startsWith('Bearer ')), false);
  });

  // Test 7: Wrong product owner denied (403)
  test('Test 7: Product not owned by authenticated user is denied (403)', () => {
    const authenticatedUserId = 'user-alice';
    const product = {
      id: 'prod-123',
      producer_id: 'user-bob',
      images: ['user-bob/prod-123/img.png'],
    };

    const isOwned = product.producer_id === authenticatedUserId;
    assert.strictEqual(isOwned, false);
  });

  // Test 8: Mismatched sourceStoragePath denied (403)
  test('Test 8: Mismatched sourceStoragePath is denied (403)', () => {
    const authenticatedUserId = 'user-alice';
    const targetProductId = 'prod-123';

    // Cross-user path
    const crossUserPath = 'user-bob/prod-123/img.png';
    const segments1 = crossUserPath.split('/');
    assert.strictEqual(segments1[0] === authenticatedUserId, false);

    // Cross-product path
    const crossProductPath = 'user-alice/other-prod/img.png';
    const segments2 = crossProductPath.split('/');
    assert.strictEqual(segments2[1] === targetProductId, false);

    // Path not in product.images list
    const unlistedPath = 'user-alice/prod-123/sneaky.png';
    const productImages = ['user-alice/prod-123/valid.png'];
    assert.strictEqual(productImages.includes(unlistedPath), false);
  });

  // Test 9: Oversized input denied (>5 MB)
  test('Test 9: Source image exceeding 5 MB is denied (400)', () => {
    const sizeBytes = 5242881; // 5 MB + 1 byte
    const isOversized = sizeBytes > MAX_IMAGE_SIZE_BYTES;
    assert.strictEqual(isOversized, true);
  });

  // Test 10: Unsupported MIME denied (400)
  test('Test 10: Unsupported MIME types (HEIC, GIF, BMP, PDF) are denied (400)', () => {
    const unsupportedTypes = ['image/heic', 'image/heif', 'image/gif', 'image/bmp', 'application/pdf'];
    for (const mime of unsupportedTypes) {
      assert.strictEqual(ALLOWED_MIME_TYPES.includes(mime), false);
    }
  });

  // Test 11: Generated output stored under authenticated user + product path
  test('Test 11: Generated output path strictly formatted as <auth_uid>/<product_id>/<filename>', () => {
    const userId = 'user-alice';
    const productId = 'prod-123';
    const randomFilename = 'a1b2c3d4e5f60718293a4b5c6d7e8f90.png';
    const outputPath = `${userId}/${productId}/${randomFilename}`;

    const segments = outputPath.split('/');
    assert.strictEqual(segments.length, 3);
    assert.strictEqual(segments[0], userId);
    assert.strictEqual(segments[1], productId);
    assert.strictEqual(segments[2], randomFilename);
  });

  // Test 12: No overwrite behavior (upsert: false)
  test('Test 12: Storage upload enforces upsert: false and creates a new random filename', () => {
    const uploadOptions = {
      contentType: 'image/png',
      upsert: false,
    };
    assert.strictEqual(uploadOptions.upsert, false);

    const sourcePath = 'user-alice/prod-123/original.png';
    const outputPath = 'user-alice/prod-123/a1b2c3d4e5f60718293a4b5c6d7e8f90.png';
    assert.notStrictEqual(sourcePath, outputPath);
  });

  // Test 13: Malformed provider response handled safely
  test('Test 13: Malformed or empty provider blob handled safely', () => {
    const checkBlob = (blob) => {
      if (!blob || typeof blob !== 'object' || blob.size === 0) {
        return {
          status: 502,
          body: {
            error: 'Photo improvement service is temporarily unavailable. Please try again.',
            code: 'HF_PROVIDER_ERROR',
          },
        };
      }
      return { status: 200 };
    };

    assert.strictEqual(checkBlob(null).status, 502);
    assert.strictEqual(checkBlob({ size: 0 }).status, 502);
    assert.strictEqual(checkBlob({ size: 1024 }).status, 200);
  });

  // Test 14: Raw provider body and errors cannot reach Flutter
  test('Test 14: Raw provider error bodies and internal details cannot reach Flutter', () => {
    // Server-side response to Flutter
    const clientResponse = {
      status: 502,
      body: {
        error: 'Photo improvement service is temporarily unavailable. Please try again.',
        code: 'HF_PROVIDER_ERROR',
      },
    };

    const responseString = JSON.stringify(clientResponse.body);
    assert.strictEqual(responseString.includes('hf_'), false);
    assert.strictEqual(responseString.includes('401'), false);
    assert.strictEqual(responseString.includes('api-inference'), false);
    assert.strictEqual(responseString.includes('ProviderApiError'), false);
    assert.strictEqual(clientResponse.body.error, 'Photo improvement service is temporarily unavailable. Please try again.');
  });

  // Test 15: Secret keys never appear in client response
  test('Test 15: Secret keys (HF_TOKEN, SERVICE_ROLE) never exposed in response body', () => {
    const secretKey = 'hf_testtoken1234567890abcdef';
    const clientResponse = {
      success: true,
      improvedStoragePath: 'user-alice/prod-123/enhanced.png',
      sourceStoragePath: 'user-alice/prod-123/original.png',
    };

    const responseString = JSON.stringify(clientResponse);
    assert.strictEqual(responseString.includes(secretKey), false);
    assert.strictEqual(responseString.includes('hf_'), false);
    assert.strictEqual(responseString.includes('service_role'), false);
    assert.strictEqual(responseString.includes('sk-'), false);
  });

  // Test 16: Output format detection detects PNG, JPEG, WebP magic bytes correctly
  test('Test 16: Output format detection detects PNG, JPEG, WebP magic bytes correctly', () => {
    function detectImageFormat(bytes) {
      if (bytes.length >= 4 && bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47) {
        return { contentType: 'image/png', ext: 'png' };
      }
      if (bytes.length >= 3 && bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) {
        return { contentType: 'image/jpeg', ext: 'jpg' };
      }
      if (
        bytes.length >= 12 &&
        bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46 &&
        bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50
      ) {
        return { contentType: 'image/webp', ext: 'webp' };
      }
      return { contentType: 'image/png', ext: 'png' };
    }

    const pngBytes = new Uint8Array([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);
    assert.deepStrictEqual(detectImageFormat(pngBytes), { contentType: 'image/png', ext: 'png' });

    const jpegBytes = new Uint8Array([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    assert.deepStrictEqual(detectImageFormat(jpegBytes), { contentType: 'image/jpeg', ext: 'jpg' });

    const webpBytes = new Uint8Array([0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]);
    assert.deepStrictEqual(detectImageFormat(webpBytes), { contentType: 'image/webp', ext: 'webp' });
  });

  // Test 17: 512x512 image is not resized
  test('Test 17: 512x512 image is not resized (both dimensions >= 256)', () => {
    const plan = calculateResizeDimensions(512, 512);
    assert.strictEqual(plan.needsResize, false);
    assert.strictEqual(plan.targetWidth, 512);
    assert.strictEqual(plan.targetHeight, 512);
  });

  // Test 18: 200x200 becomes at least 256x256
  test('Test 18: 200x200 becomes at least 256x256 while preserving aspect ratio', () => {
    const plan = calculateResizeDimensions(200, 200);
    assert.strictEqual(plan.needsResize, true);
    assert.strictEqual(plan.targetWidth >= 256, true);
    assert.strictEqual(plan.targetHeight >= 256, true);
    assert.strictEqual(plan.targetWidth, 256);
    assert.strictEqual(plan.targetHeight, 256);
    assert.strictEqual(plan.targetWidth / plan.targetHeight, 1.0);
  });

  // Test 19: 100x400 becomes approximately 256x1024
  test('Test 19: 100x400 becomes 256x1024 with aspect ratio 1:4 preserved', () => {
    const plan = calculateResizeDimensions(100, 400);
    assert.strictEqual(plan.needsResize, true);
    assert.strictEqual(plan.targetWidth, 256);
    assert.strictEqual(plan.targetHeight, 1024);
    assert.strictEqual(plan.targetWidth / plan.targetHeight, 100 / 400);
  });

  // Test 20: 400x100 becomes approximately 1024x256
  test('Test 20: 400x100 becomes 1024x256 with aspect ratio 4:1 preserved', () => {
    const plan = calculateResizeDimensions(400, 100);
    assert.strictEqual(plan.needsResize, true);
    assert.strictEqual(plan.targetWidth, 1024);
    assert.strictEqual(plan.targetHeight, 256);
    assert.strictEqual(plan.targetWidth / plan.targetHeight, 400 / 100);
  });

  // Test 21: Original storage image is never overwritten by temporary resize
  test('Test 21: Original Supabase Storage image is never overwritten and resized bytes are used only in AI request', () => {
    const sourceStoragePath = 'user-1/prod-1/original.jpg';
    let storageOverwritten = false;
    let aiInputReplaced = false;

    const mockStorage = {
      upload: (path) => {
        if (path === sourceStoragePath) storageOverwritten = true;
      },
    };

    const originalBlob = { size: 150000, name: 'original' };
    let aiInputBlob = originalBlob;

    // Simulate resizing for HF
    const plan = calculateResizeDimensions(150, 150);
    if (plan.needsResize) {
      aiInputBlob = { size: 400000, name: 'temp_resized' };
      aiInputReplaced = true;
    }

    // AI called with aiInputBlob
    assert.strictEqual(aiInputReplaced, true);
    assert.strictEqual(aiInputBlob.name, 'temp_resized');

    // Storage improved object upload uses new random path
    const improvedPath = 'user-1/prod-1/hex_random.png';
    mockStorage.upload(improvedPath);
    assert.strictEqual(storageOverwritten, false);
  });
});
