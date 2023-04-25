import Foundation

private class Constrant {
    
    static let shared = Constrant()
    
    lazy var dateformatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
        return formatter
    }()
    
}

public func printlog<T>(_ message: T, line: Int = #line) {
    let date = Constrant.shared.dateformatter.string(from: Date())
    let text = "[Vapor] [\(date)] [line: \(line)]: \(message)"
    print("\(text)")
}
