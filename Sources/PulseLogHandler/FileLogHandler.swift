//
//  FileLogHandler.swift
//  xxf_ios
//  进行多种策略 异步+分片+分时...
//  Created by xxf on 2025/5/30.
//

import Foundation
import Logging

/// 异步记录文件日志处理器，支持按日期（yyyyMMdd）和文件大小切片写入
public final class FileLogHandler: LogHandler, @unchecked Sendable {
    private let label: String
    private let logDirectory: URL
    private let fileExtension: String
    private let maxFileSizeBytes: UInt64
    private let maxRetentionDays: Int?
    private let queue: DispatchQueue

    private let dateFormatter: DateFormatter
    private var currentDateString: String

    private var currentFileIndex: Int = 0
    private var currentFileURL: URL
    private var currentFileHandle: FileHandle?
    private var currentFileSize: UInt64 = 0

    private var buffer = Data()
    private let bufferMaxSize: Int
    private let flushInterval: TimeInterval
    private var flushTimer: DispatchSourceTimer?

    private var lastLogTimestamp: String = ""
    private var lastLogTimestampDate: Date = .distantPast

    public var metadata: Logger.Metadata = [:]
    public var logLevel: Logger.Level

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    /// 初始化
    /// - Parameters:
    ///   - label: 日志标签
    ///   - logDirectory: 日志存放目录
    ///   - fileExtension: 日志文件后缀，默认 "log"
    ///   - maxFileSizeMB: 单个日志文件最大大小（MB），超过则切片
    ///   - maxRetentionDays: 日志保留天数，超过则删除
    ///   - logLevel: 记录的最低日志级别
    ///   - bufferMaxSize: 缓存最大字节数，超过立即flush
    ///   - flushInterval: 最大缓存刷新时间间隔(秒)
    ///   - qos: 异步队列优先级
    public init(label: String,
                logDirectory: URL,
                fileExtension: String = "log",
                maxFileSizeMB: UInt64 = 10,
                maxRetentionDays: Int? = nil,
                logLevel: Logger.Level = .debug,
                bufferMaxSize: Int = 16 * 1024,
                flushInterval: TimeInterval = 1.0,
                qos: DispatchQoS = .userInitiated)
    {
        self.label = label
        self.logDirectory = logDirectory
        self.fileExtension = fileExtension
        maxFileSizeBytes = maxFileSizeMB * 1024 * 1024
        self.maxRetentionDays = maxRetentionDays
        self.logLevel = logLevel

        self.bufferMaxSize = bufferMaxSize
        self.flushInterval = flushInterval

        queue = DispatchQueue(label: "com.xxf.logging.rotatingfile", qos: qos)

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        currentDateString = dateFormatter.string(from: Date())

        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)

        currentFileIndex = Self.maxFileIndex(for: currentDateString, ext: fileExtension, dir: logDirectory)
        currentFileURL = Self.fileURL(for: currentDateString, index: currentFileIndex, ext: fileExtension, dir: logDirectory)
        currentFileHandle = Self.openFileHandle(at: currentFileURL)
        currentFileSize = Self.fileSize(at: currentFileURL)

        setupFlushTimer()
        cleanupOldLogsIfNeeded()
    }

    deinit {
        flushTimer?.cancel()
        flushTimer = nil
        flush()
        closeCurrentFile()
    }

    /// 写日志
    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source _: String,
                    file _: String,
                    function _: String,
                    line _: UInt)
    {
        guard level >= logLevel else { return }

        // 预构建日志时间戳，秒级缓存，避免频繁格式化
        let now = Date()
        var timestamp: String
        if now.timeIntervalSince(lastLogTimestampDate) >= 1 {
            timestamp = Self.timestamp(from: now)
            lastLogTimestamp = timestamp
            lastLogTimestampDate = now
        } else {
            timestamp = lastLogTimestamp
        }

        var logLine = "\(timestamp) [\(level)] \(message)\n"
        if let md = metadata, !md.isEmpty {
            logLine += "Metadata: \(md)\n"
        }

        guard let data = logLine.data(using: .utf8) else { return }

        queue.async { [weak self] in
            guard let self = self else { return }

            // 日期切换检查
            let today = self.dateFormatter.string(from: Date())
            if today != self.currentDateString {
                self.rotateFile(dateString: today, resetIndex: true)
            }
            // 文件大小切片
            else if self.currentFileSize + UInt64(data.count) > self.maxFileSizeBytes {
                self.rotateFile(dateString: today, resetIndex: false)
            }

            // 缓存写入
            self.buffer.append(data)
            self.currentFileSize += UInt64(data.count)

            // 超过缓存阈值立即flush
            if self.buffer.count >= self.bufferMaxSize {
                self.flushBuffer()
            }
        }
    }

    /// 立即刷新缓存到文件
    public func flush() {
        queue.async {
            self.flushBuffer()
        }
    }

    // MARK: - 私有方法

    private func rotateFile(dateString: String, resetIndex: Bool) {
        flushBuffer()
        closeCurrentFile()

        currentDateString = dateString

        if resetIndex {
            currentFileIndex = Self.maxFileIndex(for: dateString, ext: fileExtension, dir: logDirectory) + 1
        } else {
            currentFileIndex += 1
        }

        currentFileURL = Self.fileURL(for: dateString, index: currentFileIndex, ext: fileExtension, dir: logDirectory)
        currentFileHandle = Self.openFileHandle(at: currentFileURL)
        currentFileSize = Self.fileSize(at: currentFileURL)

        cleanupOldLogsIfNeeded()
    }

    private func flushBuffer() {
        guard !buffer.isEmpty else { return }
        guard let handle = currentFileHandle else {
            buffer.removeAll()
            return
        }

        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: buffer)
            buffer.removeAll(keepingCapacity: true)
        } catch {
            #if DEBUG
            print("🛑 AsyncRotatingFileLogHandler flush failed: \(error)")
            #endif
            // 关闭文件并尝试重新打开避免死锁
            closeCurrentFile()
            currentFileHandle = Self.openFileHandle(at: currentFileURL)
        }
    }


    private func closeCurrentFile() {
        do {
            try currentFileHandle?.close()
        } catch {
            #if DEBUG
                print("⚠️ AsyncRotatingFileLogHandler close file failed: \(error)")
            #endif
        }
        currentFileHandle = nil
    }

    private func setupFlushTimer() {
        flushTimer = DispatchSource.makeTimerSource(queue: queue)
        flushTimer?.schedule(deadline: .now() + flushInterval, repeating: flushInterval)
        flushTimer?.setEventHandler { [weak self] in
            self?.flushBuffer()
        }
        flushTimer?.resume()
    }

    private func cleanupOldLogsIfNeeded() {
        guard let maxDays = maxRetentionDays else { return }

        queue.async {
            Self.cleanOldLogs(in: self.logDirectory, fileExtension: self.fileExtension, maxDays: maxDays)
        }
    }

    // MARK: - 静态工具

    private static func fileURL(for dateString: String, index: Int, ext: String, dir: URL) -> URL {
        let fileName = "\(dateString)_\(index).\(ext)"
        return dir.appendingPathComponent(fileName)
    }

    private static func openFileHandle(at url: URL) -> FileHandle? {
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        return try? FileHandle(forWritingTo: url)
    }

    private static func fileSize(at url: URL) -> UInt64 {
        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attr?[.size] as? UInt64 ?? 0
    }

    private static func timestamp(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ" // ISO8601 格式，带毫秒和时区
        formatter.locale = Locale(identifier: "en_US_POSIX")    // 保证格式固定
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") // 东八区
        return formatter.string(from: date)
    }

    /// 删除超过保留天数的日志文件（通过文件名日期判断）
    private static func cleanOldLogs(in directory: URL, fileExtension: String, maxDays: Int) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return }

        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date.distantPast

        for fileURL in files where fileURL.pathExtension == fileExtension {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            // 文件名格式: yyyyMMdd_index
            let parts = filename.split(separator: "_")
            if let dateStr = parts.first,
               let fileDate = parseDate(from: String(dateStr))
            {
                if fileDate < cutoffDate {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }
    }

    private static func parseDate(from string: String) -> Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        return df.date(from: string)
    }

    /// 查找指定日期的最大切片索引，防止覆盖
    private static func maxFileIndex(for dateString: String, ext _: String, dir: URL) -> Int {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return 0 }
        let prefix = "\(dateString)_"
        let indexes = files.compactMap { url -> Int? in
            let name = url.deletingPathExtension().lastPathComponent
            guard name.hasPrefix(prefix) else { return nil }
            return Int(name.replacingOccurrences(of: prefix, with: ""))
        }
        return indexes.max() ?? 0
    }
}
