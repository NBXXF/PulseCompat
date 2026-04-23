//
//  NetworkLogger+Headers.swift
//  PulseCompat
//
//  Created by xxf on 2026/4/23.
//

import Foundation

public extension NetworkLogger {
    /// 允许记录的 header 键集合。为空时不启用过滤,记录全部 header;
    /// 非空时仅保留集合中包含的 key(大小写不敏感)。
    nonisolated(unsafe) static var includeHeaderKeys: Set<String> = []

    
    /// 强烈注释：https://github.com/kean/Pulse/issues/268 解决urlRequest.allHTTPHeaderFields 部分机型闪退
    /// 避免 urlRequest.allHTTPHeaderFields 部分机型闪退:
    /// 用 value(forHTTPHeaderField:) 按 key 逐个读取,且仅读取白名单内的 key。
    ///
    /// - Returns: `includeHeaderKeys` 为空时返回 `nil`,调用方回退到默认行为;
    ///   非空时返回按白名单过滤后的 headers(可能为空字典)。
    static func includeHeaders(_ urlRequest: URLRequest) -> [String: String]? {
        guard !includeHeaderKeys.isEmpty else { return nil }
        var result: [String: String] = [:]
        for key in includeHeaderKeys {
            if let value = urlRequest.value(forHTTPHeaderField: key) {
                result[key] = value
            }
        }
        return result
    }
}
