// utils.ts - Utility helper functions

/**
 * Detect image media type from base64 data prefix
 * @param base64 - Base64 encoded image string
 * @returns Media type string (image/jpeg, image/png, etc.)
 */
export function detectMediaType(base64: string): string {
  const prefix = base64.substring(0, 20)

  if (prefix.startsWith('/9j/')) return 'image/jpeg'
  if (prefix.startsWith('iVBORw0KGgo')) return 'image/png'
  if (prefix.startsWith('R0lGOD')) return 'image/gif'
  if (prefix.startsWith('UklGR')) return 'image/webp'

  // Default to JPEG if unsure (most common for screenshots)
  return 'image/jpeg'
}
