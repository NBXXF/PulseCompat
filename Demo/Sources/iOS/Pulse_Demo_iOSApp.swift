// The MIT License (MIT)
//
// Copyright (c) 2020-2024 Alexander Grebenyuk (github.com/kean).

import Pulse
import PulseProxy
import PulseUI
import SwiftUI

@main
struct PulseDemo_iOS: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ConsoleView(store: .shared)
            }
        }
    }
}

private final class AppViewModel: ObservableObject {
    init() {
        // - warning: If you are testing it, make sure to switch the demo to use
        // the shared store.

        // NetworkLogger.enableProxy()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            sendRequest()
        }
    }
}

private func sendRequest() {
    // testClosures()
    // testSwiftConcurrency()
}

private func testClosures() {
    let session = URLSessionProxy(configuration: .default)
    let dataTask = session.dataTask(with: URLRequest(url: URL(string: "https://api.github.com/repos/octocat/Spoon-Knife/issues?per_page=2")!)) { data, _, _ in
        NSLog("didFinish: \(data?.count ?? 0)")
    }
    dataTask.resume()

    let downloadTask = session.downloadTask(with: URLRequest(url: URL(string: "https://api.github.com/repos/octocat/Spoon-Knife/issues?per_page=2")!)) { url, _, _ in
        NSLog("didFinish: \(String(describing: url))")
    }
    downloadTask.resume()
}

private func testSwiftConcurrency() {
    Task {
        let demoDelegate = DemoSessionDelegate()
        let session = URLSessionProxy(configuration: .default, delegate: demoDelegate, delegateQueue: nil)
//        let session = URLSession(configuration: .default)

        let (data, _) = try await session.data(from: URL(string: "https://api.github.com/repos/octocat/Spoon-Knife/issues?per_page=2")!)
        NSLog("didFinish: \(data.count)")
    }

    Task {
        let session = URLSessionProxy(configuration: .default)

        let (url, _) = try await session.download(from: URL(string: "https://api.github.com/repos/octocat/Spoon-Knife/issues?per_page=2")!, delegate: nil)
        NSLog("didFinish: \(url)")
    }
}

private final class DemoSessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        NSLog("[\(dataTask.taskIdentifier)] didReceive: \(data.count)")
    }

    func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        NSLog("[\(task.taskIdentifier)] didFinishCollectingMetrics: \(metrics)")
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        NSLog("[\(task.taskIdentifier)] didCompleteWithError: \(String(describing: error))")
    }
}
