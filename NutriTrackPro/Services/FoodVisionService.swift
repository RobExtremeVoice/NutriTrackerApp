import Foundation
import UIKit

// MARK: – Response types

struct FoodAnalysisResult: Codable {
    var mealName: String
    var confidence: String
    var foods: [FoodAnalysisItem]
    var portionNote: String?
}

struct FoodAnalysisItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var estimatedWeightG: Double
    var confidence: String
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double

    enum CodingKeys: String, CodingKey {
        case name, estimatedWeightG, confidence, calories
        case proteinG, carbsG, fatG, fiberG
    }
}

// MARK: – Service

/// Actor que analisa imagens de alimentos via GPT-4o Vision.
actor FoodVisionService {
    static let shared = FoodVisionService()
    private init() {}

    private var apiKey: String { AppConstants.openAIKey }

    /// Analisa uma descrição textual de refeição usando GPT-4o (sem imagem).
    func analyzeText(_ description: String) async throws -> FoodAnalysisResult {
        guard !apiKey.isEmpty, apiKey != "sk-proj-your_openai_key_here" else {
            throw VisionError.missingAPIKey
        }

        let prompt = """
        Analise esta descrição de refeição e retorne a estimativa nutricional.
        Descrição: \(description)

        Responda APENAS com JSON válido, sem markdown, neste formato exato:
        {
          "mealName": "Nome descritivo da refeição em Português",
          "confidence": "high|medium|low",
          "foods": [
            {
              "name": "Nome do alimento em Português",
              "estimatedWeightG": 150,
              "confidence": "medium",
              "calories": 250,
              "proteinG": 30,
              "carbsG": 10,
              "fatG": 8,
              "fiberG": 2
            }
          ],
          "portionNote": "Estimado para 1 porção média"
        }
        """

        let body: [String: Any] = [
            "model": AppConstants.chatModel,
            "max_tokens": 1200,
            "messages": [["role": "user", "content": prompt]]
        ]

        var request = URLRequest(url: URL(string: AppConstants.openAIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw VisionError.invalidResponse }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Erro \(http.statusCode)"
            throw VisionError.apiError(msg)
        }
        return try parseResponse(data)
    }

    func analyze(imageData: Data) async throws -> FoodAnalysisResult {
        guard !apiKey.isEmpty, apiKey != "sk-proj-your_openai_key_here" else {
            throw VisionError.missingAPIKey
        }

        // Comprimir imagem para reduzir tokens
        let compressedData = compressImage(imageData) ?? imageData
        let base64 = compressedData.base64EncodedString()

        let prompt = """
        Analise esta imagem de comida. Identifique TODOS os alimentos visíveis.
        Responda APENAS com JSON válido, sem markdown, neste formato exato:
        {
          "mealName": "Nome descritivo da refeição em Português",
          "confidence": "high|medium|low",
          "foods": [
            {
              "name": "Nome do alimento em Português",
              "estimatedWeightG": 150,
              "confidence": "high|medium|low",
              "calories": 250,
              "proteinG": 30,
              "carbsG": 10,
              "fatG": 8,
              "fiberG": 2
            }
          ],
          "portionNote": "Estimado para 1 porção média"
        }
        """

        let body: [String: Any] = [
            "model": AppConstants.visionModel,
            "max_tokens": 1200,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image_url",
                     "image_url": ["url": "data:image/jpeg;base64,\(base64)", "detail": "high"]],
                    ["type": "text", "text": prompt]
                ]
            ]]
        ]

        var request = URLRequest(url: URL(string: AppConstants.openAIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw VisionError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Erro \(http.statusCode)"
            throw VisionError.apiError(msg)
        }

        return try parseResponse(data)
    }

    // MARK: – Private helpers

    private func parseResponse(_ data: Data) throws -> FoodAnalysisResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first   = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw VisionError.parseError("Resposta inválida da API")
        }

        // Extrair JSON puro do conteúdo (remover markdown se presente)
        let jsonString = extractJSON(from: content)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw VisionError.parseError("Não foi possível converter o texto para dados")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(FoodAnalysisResult.self, from: jsonData)
    }

    private func extractJSON(from text: String) -> String {
        // Remove blocos de markdown ```json ... ```
        if let start = text.range(of: "{"),
           let end   = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }

    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        // Redimensionar para max 1024px e comprimir
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale: CGFloat
        if size.width > maxDimension || size.height > maxDimension {
            scale = maxDimension / max(size.width, size.height)
        } else {
            scale = 1.0
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized  = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

// MARK: – Errors

enum VisionError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Chave da API OpenAI não configurada. Adicione em Config.xcconfig."
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .apiError(let msg):
            return "Erro da API: \(msg)"
        case .parseError(let msg):
            return "Erro ao processar resposta: \(msg)"
        }
    }
}
