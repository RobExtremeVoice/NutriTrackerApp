import Foundation

// MARK: – Data types

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: String   // "user" | "assistant"
    var content: String
    var timestamp: Date = .now

    var isUser: Bool { role == "user" }
}

// MARK: – Service

/// Actor responsável pelo streaming de mensagens GPT-4o.
actor ChatService {
    static let shared = ChatService()
    private init() {}

    private var apiKey: String { AppConstants.openAIKey }

    /// Envia mensagens ao GPT-4o e retorna os tokens via AsyncStream.
    func sendStream(
        messages: [ChatMessage],
        systemPrompt: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.stream(
                        messages: messages,
                        systemPrompt: systemPrompt,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: – Private

    private func stream(
        messages: [ChatMessage],
        systemPrompt: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard !apiKey.isEmpty, apiKey != "sk-proj-your_openai_key_here" else {
            throw ChatError.missingAPIKey
        }

        var payload: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for m in messages {
            payload.append(["role": m.role, "content": m.content])
        }

        let body: [String: Any] = [
            "model": AppConstants.chatModel,
            "stream": true,
            "max_tokens": 800,
            "messages": payload
        ]

        var request = URLRequest(url: URL(string: AppConstants.openAIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ChatError.invalidResponse
        }

        for try await line in bytes.lines {
            // SSE format: "data: {...}" or "data: [DONE]"
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            guard jsonStr != "[DONE]" else { break }

            if let data   = jsonStr.data(using: .utf8),
               let json   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let delta  = choices.first?["delta"] as? [String: Any],
               let token  = delta["content"] as? String {
                continuation.yield(token)
            }
        }
    }
}

// MARK: – Errors

enum ChatError: LocalizedError {
    case missingAPIKey
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Chave da API OpenAI não configurada."
        case .invalidResponse:
            return "Resposta inválida do servidor de chat."
        }
    }
}
