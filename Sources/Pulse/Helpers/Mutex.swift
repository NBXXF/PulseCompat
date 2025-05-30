// The MIT License (MIT)
//
// 

import Foundation

package final class Mutex<T>: @unchecked Sendable {
    private var _value: T
    private let lock: os_unfair_lock_t

    package init(_ value: T) {
        _value = value
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    package var value: T {
        get {
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return _value
        }
        set {
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            _value = newValue
        }
    }

    package func withLock<U>(_ closure: (inout T) -> U) -> U {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return closure(&_value)
    }
}
