import Foundation
import Cocoa

class LoggerService {
    static let shared = LoggerService()
    
    private init() {}
    
    func getLogDirectory() -> URL? {
        let fileManager = FileManager.default
        do {
            let appSupportDirectory = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let learnPartnerDirectory = appSupportDirectory.appendingPathComponent("LearnPartner")
            
            if !fileManager.fileExists(atPath: learnPartnerDirectory.path) {
                try fileManager.createDirectory(at: learnPartnerDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            return learnPartnerDirectory
        } catch {
            print("无法获取应用支持目录: \(error)")
            return nil
        }
    }
    
    func log(_ message: String) {
        guard let appSupportDirectory = getLogDirectory() else {
            return
        }
        
        let logFile = appSupportDirectory.appendingPathComponent(AppConfig.logFileName)
        let logMessage = "\(Date()): \(message)\n"
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            try? logMessage.write(to: logFile, atomically: true, encoding: .utf8)
        }
    }
    
    func clearLogs() {
        guard let appSupportDirectory = getLogDirectory() else {
            return
        }
        
        let logFile = appSupportDirectory.appendingPathComponent(AppConfig.logFileName)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: logFile.path) {
            do {
                try fileManager.removeItem(atPath: logFile.path)
                let emptyString = ""
                try emptyString.write(to: logFile, atomically: true, encoding: .utf8)
                log("日志文件已清除")
            } catch {
                print("清除日志文件时出错: \(error)")
            }
        }
    }
    
    func deleteOldLogs(maxDays: Int = AppConfig.maxLogDays) {
        guard let appSupportDirectory = getLogDirectory() else {
            return
        }
        
        let logFile = appSupportDirectory.appendingPathComponent(AppConfig.logFileName)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: logFile.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: logFile.path)
                
                if let creationDate = attributes[.creationDate] as? Date {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day], from: creationDate, to: Date())
                    
                    if let days = components.day, days > maxDays {
                        try fileManager.removeItem(atPath: logFile.path)
                        log("已删除超过\(maxDays)天的旧日志文件")
                    }
                }
            } catch {
                print("删除旧日志文件时出错: \(error)")
            }
        }
    }
}

func logToFile(_ message: String) {
    LoggerService.shared.log(message)
}
