import Foundation
import Cocoa

class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(_ text: String, completion: @escaping (String?) -> Void) {
        let scriptPath = Bundle.main.path(forResource: "translate", ofType: "py")
        
        guard let scriptPath = scriptPath else {
            completion(nil)
            return
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        task.arguments = ["python3", scriptPath, encodedText]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                completion(output)
            } else {
                completion(nil)
            }
        } catch {
            logToFile("翻译失败: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func saveApiKey(_ apiKey: String, completion: @escaping (Bool, String?) -> Void) {
        let scriptPath = Bundle.main.path(forResource: "translate", ofType: "py")
        
        guard let scriptPath = scriptPath else {
            completion(false, "翻译脚本不存在")
            return
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", scriptPath, "--set-api-key", apiKey]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               let jsonData = output.data(using: .utf8),
               let result = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                
                let success = result["success"] as? Bool ?? false
                let error = result["error"] as? String
                completion(success, error)
            } else {
                completion(false, "解析响应失败")
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
}
