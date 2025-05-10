import Foundation

class GeminiAPIClient {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent "
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Main function to generate MCQs from PDF content
    func generateMCQs(from pdfContent: String, completion: @escaping (Result<[MCQuestion], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // Truncate content if too large (Gemini has token limits)
        let maxContentLength = 10000
        let truncatedContent = pdfContent.count > maxContentLength ?
            String(pdfContent.prefix(maxContentLength)) + "..." : pdfContent
        
        // Create prompt for generating MCQs
        let prompt = """
        Based on the following document content, generate 5 multiple-choice questions (MCQs).
        For each question:
        1. Create a clear question based on important information in the document
        2. Provide exactly 4 options (labeled A, B, C, D)
        3. Make sure only one option is correct
        4. Indicate which option is correct
        
        Format your response as a JSON array of objects with this structure:
        [
          {
            "question": "The question text here?",
            "options": ["Option A", "Option B", "Option C", "Option D"],
            "correctAnswerIndex": 0 // Index of correct answer (0-3)
          }
        ]
        
        Document content:
        \(truncatedContent)
        """
        
        // Build request body according to Gemini API format
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024,
            ]
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(APIError.jsonEncodingFailed))
            return
        }
        
        // Set up request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Execute request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.noDataReceived))
                }
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let mcqs = self?.parseGeminiResponse(json) {
                    DispatchQueue.main.async {
                        completion(.success(mcqs))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(APIError.responseParseFailed))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // Helper to parse Gemini API response
    private func parseGeminiResponse(_ response: [String: Any]) -> [MCQuestion]? {
        guard let candidates = response["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            return nil
        }
        
        // The text will contain JSON within it - we need to extract and parse that
        return extractMCQsFromText(text)
    }
    
    // Extract JSON from text response
    private func extractMCQsFromText(_ text: String) -> [MCQuestion]? {
        // Find JSON array in the text (might be surrounded by markdown code blocks or other text)
        let pattern = "\\[\\s*\\{.*?\\}\\s*\\]"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        guard let match = regex?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) else {
            return nil
        }
        
        if let range = Range(match.range, in: text) {
            let jsonString = String(text[range])
            if let jsonData = jsonString.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                
                // Convert to our MCQuestion model
                return jsonArray.compactMap { json in
                    guard let question = json["question"] as? String,
                          let options = json["options"] as? [String],
                          let correctAnswer = json["correctAnswerIndex"] as? Int else {
                        return nil
                    }
                    
                    return MCQuestion(
                        question: question,
                        options: options,
                        correctAnswerIndex: correctAnswer
                    )
                }
            }
        }
        
        return nil
    }
    
    // Custom error types
    enum APIError: Error {
        case invalidURL
        case jsonEncodingFailed
        case noDataReceived
        case responseParseFailed
    }
}
