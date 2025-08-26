//
//  LoggerStore+Clear.swift
//  PulseCompat
//  清理内存
//  Created by xxf on 2025/8/26.
//

public extension LoggerStore {
    /// Safely clears memory caches.
    func clearMemoryCachesSafely() {
        perform { _ in
            self.clearMemoryCaches()
        }
    }

    /// Optionally, 如果需要同步版本
    func clearMemoryCachesSafelySync() {
        backgroundContext.performAndWait {
            self.clearMemoryCaches()
        }
    }
}
