import Foundation

class GeminiAPIClient {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Main function to generate MCQs from PDF content
    func generateMCQs(from pdfContent: String, completion: @escaping (Result<[MCQuestion], Error>) -> Void) {
        // Simplify the content to avoid any encoding issues
        let cleanContent = pdfContent
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
        
        // Truncate even more aggressively - focus on quality over quantity
        let maxContentLength = 2000 
        let truncatedContent = cleanContent.count > maxContentLength ?
            String(cleanContent.prefix(maxContentLength)) : cleanContent
        
        print("PDF processing: \(cleanContent.count) chars cleaned, \(truncatedContent.count) used")
        
        // Simple, direct URL with key as query parameter
        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // Create a very simple prompt
        let prompt = """
        Create 5 multiple choice questions based on this text:
        \(truncatedContent)
        
        Format each question as a JSON object with:
        - "question": The question text
        - "options": Array of 4 possible answers
        - "correctAnswerIndex": Index (0-3) of correct answer
        
        Return the results as a JSON array.
        """
        
        // Create a minimal, clean request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        // Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(APIError.jsonEncodingFailed))
            return
        }
        
        // Create a completely fresh URLSession for this request
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.httpMaximumConnectionsPerHost = 1
        let freshSession = URLSession(configuration: sessionConfig)
        
        // Create a basic request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        print("Sending request to: \(url.absoluteString)")
        
        // Create and execute the task
        freshSession.dataTask(with: request) { [weak self] data, response, error in
            // Handle errors from the network layer
            if let error = error {
                DispatchQueue.main.async {
                    print("Network error: \(error.localizedDescription)")
                    completion(.failure(APIError.networkError(description: error.localizedDescription)))
                }
                return
            }
            
            // Log status code
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("Response status: \(statusCode)")
            
            // Check for empty data
            guard let data = data, !data.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.noDataReceived))
                }
                return
            }
            
            // Log the response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = String(responseString.prefix(min(200, responseString.count)))
                print("Response preview: \(preview)")
            }
            
            // Try to parse the response
            do {
                // First attempt: Parse as JSON directly
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let mcqs = self?.parseGeminiResponse(json) {
                    DispatchQueue.main.async {
                        completion(.success(mcqs))
                    }
                    return
                }
                
                // Second attempt: Try to extract text and find JSON in it
                if let responseText = String(data: data, encoding: .utf8),
                   let mcqs = self?.extractMCQsFromText(responseText) {
                    DispatchQueue.main.async {
                        completion(.success(mcqs))
                    }
                    return
                }
                
                // Failed to parse the response
                DispatchQueue.main.async {
                    print("Could not extract MCQs from response")
                    completion(.failure(APIError.responseParseFailed))
                }
            } catch {
                DispatchQueue.main.async {
                    print("JSON parsing error: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
        
        // Invalidate the session after the request
        DispatchQueue.main.asyncAfter(deadline: .now() + 35) {
            freshSession.invalidateAndCancel()
        }
    }
    
    // Helper to parse Gemini API response
    private func parseGeminiResponse(_ response: [String: Any]) -> [MCQuestion]? {
        // Try to find the response content through different paths
        if let candidates = response["candidates"] as? [[String: Any]],
           !candidates.isEmpty,
           let firstCandidate = candidates.first {
            
            // Path 1: Through content/parts
            if let content = firstCandidate["content"] as? [String: Any] {
                if let parts = content["parts"] as? [[String: Any]],
                   !parts.isEmpty,
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    return extractMCQsFromText(text)
                }
                
                // Path 2: Direct text in content
                if let text = content["text"] as? String {
                    return extractMCQsFromText(text)
                }
            }
            
            // Path 3: Direct text in candidate
            if let text = firstCandidate["text"] as? String {
                return extractMCQsFromText(text)
            }
        }
        
        return nil
    }
    
    // Extract JSON from text response
    private func extractMCQsFromText(_ text: String) -> [MCQuestion]? {
        // Try direct JSON parse if the text looks like JSON
        if text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") {
            if let jsonData = text.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                return parseJSONArray(jsonArray)
            }
        }
        
        // Try to extract JSON from the text
        let patterns = [
            "\\[\\s*\\{.*?\\}\\s*\\]", // Standard JSON array
            "\\{\\s*\"question\".*?\\}\\s*,?\\s*\\{", // Multiple JSON objects
            "\\{\\s*\"question\".*?\\}" // Single JSON object
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               let range = Range(match.range, in: text) {
                
                // Extract the potential JSON text
                var jsonText = String(text[range])
                
                // If it's not an array but an object, wrap it
                if jsonText.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
                    jsonText = "[\(jsonText)]"
                }
                
                // Try to parse as JSON
                if let jsonData = jsonText.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                    return parseJSONArray(jsonArray)
                }
            }
        }
        
        return nil
    }
    
    // Parse JSON array into MCQuestions
    private func parseJSONArray(_ jsonArray: [[String: Any]]) -> [MCQuestion]? {
        var mcqs: [MCQuestion] = []
        
        for json in jsonArray {
            // Extract question
            guard let question = json["question"] as? String else { continue }
            
            // Extract options - try different formats
            var options: [String] = []
            
            if let optionsArray = json["options"] as? [String] {
                options = optionsArray
            } else if let optionsDict = json["options"] as? [String: String] {
                // Sort dictionary keys to maintain order (A, B, C, D)
                let sortedKeys = optionsDict.keys.sorted()
                options = sortedKeys.compactMap { optionsDict[$0] }
            } else if let optionsDict = json["options"] as? [String: Any] {
                // Try numeric keys like "0", "1", "2", "3" or "a", "b", "c", "d"
                let sortedKeys = optionsDict.keys.sorted()
                for key in sortedKeys {
                    if let option = optionsDict[key] as? String {
                        options.append(option)
                    }
                }
            }
            
            // Need at least 2 options
            guard options.count >= 2 else { continue }
            
            // Get correct answer index
            var correctIndex = 0
            
            if let index = json["correctAnswerIndex"] as? Int {
                correctIndex = index
            } else if let correctAnswer = json["correctAnswer"] as? String {
                if let index = Int(correctAnswer) {
                    correctIndex = index
                } else if correctAnswer.count == 1, 
                          let ascii = correctAnswer.first?.asciiValue,
                          ascii >= 65 && ascii <= 68 {
                    // Handle "A", "B", "C", "D"
                    correctIndex = Int(ascii - 65)
                }
            }
            
            // Ensure the index is valid
            correctIndex = min(correctIndex, options.count - 1)
            
            let mcq = MCQuestion(
                question: question,
                options: options,
                correctAnswerIndex: correctIndex
            )
            mcqs.append(mcq)
        }
        
        return mcqs.isEmpty ? nil : mcqs
    }
    
    // Custom error types
    enum APIError: Error, LocalizedError {
        case invalidURL
        case jsonEncodingFailed
        case noDataReceived
        case responseParseFailed
        case networkError(description: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .jsonEncodingFailed:
                return "Failed to encode request"
            case .noDataReceived:
                return "No data received from server"
            case .responseParseFailed:
                return "Failed to parse API response"
            case .networkError(let description):
                return "Network error: \(description)"
            }
        }
    }
}
