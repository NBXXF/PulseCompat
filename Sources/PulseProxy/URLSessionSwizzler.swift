// The MIT License (MIT)
//
// 

import Foundation
import Pulse

public extension NetworkLogger {
    /// Enables automatic logging and remote debugging of network requests.
    ///
    /// - warning: This method of logging relies heavily on swizzling and might
    /// stop working in the future versions of the native SDKs. If you are looking
    /// for a more stable solution, consider using ``URLSessionProxyDelegate`` or
    /// manually logging the requests using ``NetworkLogger``.
    ///
    /// - parameter logger: The network logger to be used for recording the requests. By default, uses shared logger.
    static func enableProxy(logger: NetworkLogger? = nil) {
        URLSessionSwizzler.enable(logger: logger)
    }
}

final class URLSessionSwizzler {
    static var shared: URLSessionSwizzler?

    private var logger: NetworkLogger { _logger ?? .shared }
    private let _logger: NetworkLogger?

    init(logger: NetworkLogger?) {
        _logger = logger
    }

    static let lock = NSLock()
    static var isEnabled = false

    static func enable(logger: NetworkLogger?) {
        lock.lock()
        if isEnabled {
            lock.unlock()
            NSLog("Error: Pulse proxy is already enabled")
            return
        }
        isEnabled = true
        lock.unlock()

        let proxy = URLSessionSwizzler(logger: logger)
        proxy.enable()
        URLSessionSwizzler.shared = proxy
    }

    func enable() {
        swizzleURLSessionTaskResume()
        // "__NSCFURLLocalSessionConnection"
        if let sessionClass = NSClassFromString(["__", "NS", "CFURL", "Local", "Session", "Connection"].joined()) {
            swizzleDataTaskDidReceiveData(baseClass: sessionClass)
            swizzleDataDataDidCompleteWithError(baseClass: sessionClass)
        } else {
            NSLog("Pulse.URLSessionSwizzler failed to initialize. Please report at https://github.com/kean/Pulse/issues.")
        }
    }

    // - `resume` (optional)
    private func swizzleURLSessionTaskResume() {
        var methods = [Method]()
        if let method = class_getInstanceMethod(URLSessionTask.self, #selector(URLSessionTask.resume)) {
            methods.append(method)
        }
        // "__NSCFURLSessionTask"
        if let sessionTaskClass = NSClassFromString(["__", "NS", "CFURL", "Session", "Task"].joined()),
           let method = class_getInstanceMethod(sessionTaskClass, NSSelectorFromString("resume"))
        {
            methods.append(method)
        }
        for item in methods {
            let method = item
            var originalImplementation: IMP?
            let block: @convention(block) (URLSessionTask) -> Void = { [weak self] task in
                self?.logger.logTaskCreated(task)

                guard task.currentRequest != nil else { return }
                let key = String(method.hashValue)
                objc_setAssociatedObject(task, key, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                let castedIMP = unsafeBitCast(originalImplementation, to: (@convention(c) (Any) -> Void).self)
                castedIMP(task)
                objc_setAssociatedObject(task, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            let swizzledIMP = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
            originalImplementation = method_setImplementation(method, swizzledIMP)
        }
    }

    // - `urlSession(_:task:didCompleteWithError:)`
    func swizzleDataDataDidCompleteWithError(baseClass: AnyClass) {
        // "_didFinishWithError:"
        let selector = NSSelectorFromString(["_", "didFinish", "With", "Error", ":"].joined())
        guard let method = class_getInstanceMethod(baseClass, selector),
              baseClass.instancesRespond(to: selector)
        else {
            return
        }
        typealias MethodSignature = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let closure: @convention(block) (AnyObject, AnyObject?) -> Void = { [weak self] object, error in
            let original: MethodSignature = unsafeBitCast(originalImp, to: MethodSignature.self)
            original(object, selector, error)

            if let task = object.value(forKey: "task") as? URLSessionTask {
                // "_incompleteTaskMetrics"
                if let metrics = task.value(forKey: ["_", "incomplete", "Task", "Metrics"].joined()) as? URLSessionTaskMetrics {
                    self?.logger.logTask(task, didFinishCollecting: metrics)
                }
                if var error = error as? NSError {
                    if error.domain == "kCFErrorDomainCFNetwork" {
                        // Satisfy LogggerStore (needs refactoring)
                        error = NSError(domain: URLError.errorDomain, code: error.code, userInfo: error.userInfo)
                    }
                    self?.logger.logTask(task, didCompleteWithError: error)
                } else {
                    self?.logger.logTask(task, didCompleteWithError: error as? Error)
                }
            }
        }
        method_setImplementation(method, imp_implementationWithBlock(closure))
    }

    // - `urlSession(_:dataTask:didReceive:)`
    func swizzleDataTaskDidReceiveData(baseClass: AnyClass) {
        // "_didReceiveData"
        let selector = NSSelectorFromString(["_", "did", "Receive", "Data", ":"].joined())
        guard let method = class_getInstanceMethod(baseClass, selector),
              baseClass.instancesRespond(to: selector)
        else {
            return
        }

        typealias MethodSignature = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let closure: @convention(block) (AnyObject, AnyObject) -> Void = { [weak self] object, data in
            let original: MethodSignature = unsafeBitCast(originalImp, to: MethodSignature.self)
            original(object, selector, data)

            if let task = object.value(forKey: "task") as? URLSessionDataTask {
                let data = (data as? Data) ?? Data()
                self?.logger.logDataTask(task, didReceive: data)
            }
        }
        method_setImplementation(method, imp_implementationWithBlock(closure))
    }
}
