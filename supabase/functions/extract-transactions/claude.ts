// claude.ts - Claude API interaction and transaction extraction

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')

// Model cascade order: try best model first, fall back if overloaded
const CLAUDE_MODELS = [
  "claude-opus-4-5-20251101",      // Most capable model - Opus 4.5
  "claude-sonnet-4-5-20250929",    // Sonnet 4.5 - excellent balance
  "claude-sonnet-4-20250514",      // Sonnet 4 fallback
  "claude-3-7-sonnet-20250219",    // Solid fallback
  "claude-3-5-sonnet-20241022",    // Additional fallback
  "claude-3-5-haiku-20241022",     // Faster fallback if needed
  "claude-3-haiku-20240307"        // Last resort - fastest/cheapest
]

// Tool schema for extracting transactions from images
const extractTransactionsTool = {
  name: "extract_transactions",
  description: "Extract transaction details from a receipt or bank notification screenshot",
  input_schema: {
    type: "object",
    properties: {
      transactions: {
        type: "array",
        items: {
          type: "object",
          properties: {
            amount: { type: "number", description: "Transaction amount as a number" },
            currency: { type: "string", description: "3-letter currency code (USD, GBP, ZAR, etc.)" },
            merchant: { type: "string", description: "Merchant or vendor name" },
            transaction_date: { type: "string", description: "ISO 8601 date string if visible, otherwise null" }
          },
          required: ["amount", "currency", "merchant"]
        }
      }
    },
    required: ["transactions"]
  }
}

/**
 * Call Claude API with model cascade fallback strategy
 * Tries multiple models in order until one succeeds or all fail
 * @param image_base64 - Base64 encoded image data
 * @param media_type - Image media type (image/jpeg, image/png, etc.)
 * @returns Claude API response data and the model that was used
 */
export async function callClaudeWithCascade(image_base64: string, media_type: string) {
  let lastError = null

  for (const model of CLAUDE_MODELS) {
    try {
      console.log(`Trying model: ${model}`)

      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": ANTHROPIC_API_KEY!,
          "anthropic-version": "2023-06-01"
        },
        body: JSON.stringify({
          model,
          max_tokens: 1024,
          tools: [extractTransactionsTool],
          tool_choice: { type: "tool", name: "extract_transactions" },
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "image",
                  source: {
                    type: "base64",
                    media_type,
                    data: image_base64
                  }
                },
                {
                  type: "text",
                  text: "Extract all transactions from this screenshot. Look for amounts, currency, merchant names, and dates. If multiple transactions are visible, extract all of them (up to 12)."
                }
              ]
            }
          ]
        })
      })

      // If we get rate limited or overloaded, try next model
      if (response.status === 429 || response.status === 529) {
        const errorData = await response.json()
        console.warn(`Model ${model} overloaded/rate limited:`, errorData)
        lastError = errorData
        continue
      }

      // If other error, throw it
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(`Claude API error: ${JSON.stringify(errorData)}`)
      }

      const data = await response.json()
      console.log(`Successfully used model: ${model}`)
      return { data, model }

    } catch (err) {
      console.error(`Error with model ${model}:`, err)
      lastError = err
      // Continue to next model
    }
  }

  // All models failed
  throw new Error(`All models failed. Last error: ${JSON.stringify(lastError)}`)
}
