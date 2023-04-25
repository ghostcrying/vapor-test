//
//  File.swift
//  
//
//  Created by 陈卓 on 2023/4/19.
//

import Foundation

fileprivate let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

extension String {
    
    static func random(_ length: Int = 10) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if result == errSecSuccess {
            return Data(bytes).base64EncodedString()
        }
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
