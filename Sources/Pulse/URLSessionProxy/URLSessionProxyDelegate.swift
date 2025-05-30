// The MIT License (MIT)
//
// 

import Foundation

/// Automates URLSession request tracking.
///
/// - important: On iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, it automatically
/// tracks new task creation using the `urlSession(_:didCreateTask:)` delegate
/// method which allows the logger to start tracking network requests right
/// after their creation. On earlier versions, you can (optionally) call
/// ``NetworkLogger/logTaskCreated(_:)`` manually.
public final class URLSessionProxyDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    private let actualDelegate: URLSessionDelegate?
    private let taskDelegate: URLSessionTaskDelegate?
    private let interceptedSelectors: Set<Selector>
    private var logger: NetworkLogger { _logger ?? .shared }
    private let _logger: NetworkLogger?

    /// - parameter logger: By default, uses a shared logger
    /// - parameter delegate: The "actual" session delegate, strongly retained.
    public init(logger: NetworkLogger? = nil, delegate: URLSessionDelegate? = nil) {
        actualDelegate = delegate
        taskDelegate = delegate as? URLSessionTaskDelegate
        _logger = logger

        var interceptedSelectors: Set = [
            #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didFinishCollecting:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)),
            #selector(URLSessionDownloadDelegate.urlSession(_:downloadTask:didFinishDownloadingTo:)),
            #selector(URLSessionDownloadDelegate.urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)),
        ]
        if #available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *) {
            interceptedSelectors.insert(#selector(URLSessionTaskDelegate.urlSession(_:didCreateTask:)))
        }
        self.interceptedSelectors = interceptedSelectors
    }

    // MARK: URLSessionTaskDelegate

    let createdTask = Mutex<URLSessionTask?>(nil)

    public func urlSession(_ session: Foundation.URLSession, didCreateTask task: URLSessionTask) {
        createdTask.value = task
        logger.logTaskCreated(task)
        if #available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *) {
            taskDelegate?.urlSession?(session, didCreateTask: task)
        }
    }

    public func urlSession(_ session: Foundation.URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        logger.logTask(task, didCompleteWithError: error)
        taskDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
    }

    public func urlSession(_ session: Foundation.URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        logger.logTask(task, didFinishCollecting: metrics)
        taskDelegate?.urlSession?(session, task: task, didFinishCollecting: metrics)
    }

    public func urlSession(_ session: Foundation.URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if task is URLSessionUploadTask {
            logger.logTask(task, didUpdateProgress: (completed: totalBytesSent, total: totalBytesExpectedToSend))
        }
        (actualDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }

    // MARK: URLSessionDataDelegate

    public func urlSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        logger.logDataTask(dataTask, didReceive: data)
        (actualDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }

    // MARK: URLSessionDownloadDelegate

    public func urlSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        (actualDelegate as? URLSessionDownloadDelegate)?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }

    public func urlSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        logger.logTask(downloadTask, didUpdateProgress: (completed: totalBytesWritten, total: totalBytesExpectedToWrite))
        (actualDelegate as? URLSessionDownloadDelegate)?.urlSession?(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

    // MARK: Proxy

    override public func responds(to aSelector: Selector!) -> Bool {
        if interceptedSelectors.contains(aSelector) {
            return true
        }
        return (actualDelegate?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }

    override public func forwardingTarget(for selector: Selector!) -> Any? {
        interceptedSelectors.contains(selector) ? nil : actualDelegate
    }
}
