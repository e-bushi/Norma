//
//  AnthropicModels.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

// MARK: - Request Models

struct AnthropicRequest: Codable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [AnthropicMessage]
    let tools: [AnthropicTool]?
    let toolChoice: AnthropicToolChoice?
    let stream: Bool?
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
        case tools
        case toolChoice = "tool_choice"
        case stream
    }
}

struct AnthropicMessage: Codable {
    let role: String
    let content: AnthropicMessageContent
}

enum AnthropicMessageContent: Codable {
    case text(String)
    case toolUse(id: String, name: String, input: [String: Any])
    case toolResult(toolUseId: String, content: String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let array = try? container.decode([ContentBlock].self) {
            if let firstBlock = array.first {
                switch firstBlock.type {
                case "text":
                    self = .text(firstBlock.text ?? "")
                case "tool_use":
                    self = .toolUse(id: firstBlock.id ?? "", name: firstBlock.name ?? "", input: firstBlock.input ?? [:])
                case "tool_result":
                    self = .toolResult(toolUseId: firstBlock.toolUseId ?? "", content: firstBlock.content ?? "")
                default:
                    self = .text("")
                }
            } else {
                self = .text("")
            }
        } else {
            self = .text("")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(text)
        case .toolUse(let id, let name, let input):
            let block = ContentBlock(type: "tool_use", id: id, name: name, input: input)
            try container.encode([block])
        case .toolResult(let toolUseId, let content):
            let block = ContentBlock(type: "tool_result", toolUseId: toolUseId, content: content)
            try container.encode([block])
        }
    }
}

struct ContentBlock: Codable {
    let type: String
    let id: String?
    let name: String?
    let input: [String: Any]?
    let toolUseId: String?
    let content: String?
    let text: String?
    
    enum CodingKeys: String, CodingKey {
        case type, id, name, input, content, text
        case toolUseId = "tool_use_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        toolUseId = try container.decodeIfPresent(String.self, forKey: .toolUseId)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        
        if let inputData = try? container.decode([String: AnyCodable].self, forKey: .input) {
            input = inputData.mapValues { $0.value }
        } else {
            input = nil
        }
    }
    
    init(type: String, id: String? = nil, name: String? = nil, input: [String: Any]? = nil, toolUseId: String? = nil, content: String? = nil, text: String? = nil) {
        self.type = type
        self.id = id
        self.name = name
        self.input = input
        self.toolUseId = toolUseId
        self.content = content
        self.text = text
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(toolUseId, forKey: .toolUseId)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(text, forKey: .text)
        
        if let input = input {
            let anyCodableInput = input.mapValues { AnyCodable($0) }
            try container.encode(anyCodableInput, forKey: .input)
        }
    }
}

/// Type-erased Codable value for flexible JSON encoding
/// Used by both Anthropic API and Edge Function services
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        case let date as Date:
            try container.encode(ISO8601DateFormatter().string(from: date))
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Tool Models

struct AnthropicTool: Codable {
    let name: String
    let description: String
    let inputSchema: AnthropicToolSchema
    
    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
}

struct AnthropicToolSchema: Codable {
    let type: String
    let properties: [String: AnthropicToolProperty]
    let required: [String]
}

struct AnthropicToolProperty: Codable {
    let type: String
    let description: String?
    let `enum`: [String]?
    let items: AnthropicToolItems?

    init(
        type: String,
        description: String? = nil,
        `enum`: [String]? = nil,
        items: AnthropicToolItems? = nil
    ) {
        self.type = type
        self.description = description
        self.`enum` = `enum`
        self.items = items
    }

    enum CodingKeys: String, CodingKey {
        case type, description, items
        case `enum`
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(`enum`, forKey: .enum)
        try c.encodeIfPresent(items, forKey: .items)
    }
}

/// Schema for `array` items — supports nested object schemas with their own
/// properties + required list. Used for tool inputs like `tokens: [Token]`.
struct AnthropicToolItems: Codable {
    let type: String
    let properties: [String: AnthropicToolProperty]?
    let required: [String]?

    init(type: String, properties: [String: AnthropicToolProperty]? = nil, required: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

struct AnthropicToolChoice: Codable {
    let type: String
    let name: String?
}

// MARK: - Response Models

struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
    let model: String
    let role: String
    let stopReason: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case model
        case role
        case stopReason = "stop_reason"
    }
}

struct AnthropicContent: Codable {
    let type: String
    let text: String?
    let id: String?
    let name: String?
    let input: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case type, text, id, name, input
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        if let inputData = try? container.decode([String: AnyCodable].self, forKey: .input) {
            input = inputData.mapValues { $0.value }
        } else {
            input = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        
        if let input = input {
            let anyCodableInput = input.mapValues { AnyCodable($0) }
            try container.encode(anyCodableInput, forKey: .input)
        }
    }
}

struct AnthropicErrorResponse: Codable {
    let error: AnthropicErrorDetail
}

struct AnthropicErrorDetail: Codable {
    let type: String
    let message: String
}

// MARK: - Onboarding Models

struct UserOnboardingData: Codable {
    var name: String = ""
    var currency: String = "USD"
    var monthlyIncome: Double = 0  // Derived monthly figure (amount × cadence).
    var freedomFund: Double = 0
    var painPoint: String = ""
    var reminderPreference: String = ""

    // Flexible pay cadence captured in onboarding. `monthlyIncome` above is the
    // derived monthly (for settings); these carry the per-paycheck truth so the
    // local UserProfile stores the real cadence. Exact day-of-week/month is
    // defaulted here and refined later in the calendar/profile editor.
    var incomeAmountPerPaycheck: Double = 0
    var incomeCadenceRaw: String = "monthly"  // weekly|biweekly|semiMonthly|monthly|irregular
}

// MARK: - Errors

// MARK: - Streaming Response Models

struct AnthropicStreamResponse: Codable {
    let type: String
    let message: AnthropicStreamMessage?
    let index: Int?
    let delta: AnthropicStreamDelta?
    let usage: AnthropicStreamUsage?
    
    enum CodingKeys: String, CodingKey {
        case type, message, index, delta, usage
    }
}

struct AnthropicStreamMessage: Codable {
    let id: String?
    let type: String?
    let role: String?
    let content: [AnthropicContent]?
    let model: String?
    let usage: AnthropicStreamUsage?
}

struct AnthropicStreamDelta: Codable {
    let type: String?
    let text: String?
    let stopReason: String?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case stopReason = "stop_reason"
    }
}

struct AnthropicStreamUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Error Models

enum AnthropicError: LocalizedError {
    case networkError
    case apiError(String)
    case dataParsingError
    case unknownError(Int)
    case rateLimited
    case invalidResponse
    case allModelsFailed
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .apiError(let message):
            return "API Error: \(message)"
        case .dataParsingError:
            return "Failed to parse response data."
        case .unknownError(let statusCode):
            return "Unknown error occurred. Status code: \(statusCode)"
        case .rateLimited:
            return "Rate limited by API."
        case .invalidResponse:
            return "Invalid response from API."
        case .allModelsFailed:
            return "All models failed to respond."
        }
    }
}