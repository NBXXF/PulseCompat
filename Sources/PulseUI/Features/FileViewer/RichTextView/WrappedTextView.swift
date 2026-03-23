// The MIT License (MIT)
//
// 

#if os(iOS) || os(macOS) || os(visionOS)

    import Combine
    import SwiftUI

    #if os(iOS) || os(visionOS)

        struct WrappedTextView: UIViewRepresentable {
            let viewModel: RichTextViewModel

            @ObservedObject private var settings = UserSettings.shared

            final class Coordinator: NSObject, UITextViewDelegate {
                var onLinkTapped: ((URL) -> Bool)?
                var cancellables: [AnyCancellable] = []

                func textView(_: UITextView, shouldInteractWith URL: URL, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
                    if let onLinkTapped = onLinkTapped, onLinkTapped(URL) {
                        return false
                    }
                    if let (title, message) = parseTooltip(URL) {
                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        alert.addAction(.init(title: "Done", style: .cancel))
                        UIApplication.keyWindow?.rootViewController?.present(alert, animated: true)

                        return false
                    }
                    return true
                }
            }

            func makeUIView(context: Context) -> UXTextView {
                let textView: KeyboardEnabledTextView
                if #available(iOS 16, *) {
                    // Disables the new TextKit 2 which is extremely slow on iOS 16
                    textView = KeyboardEnabledTextView(usingTextLayoutManager: false)
                } else {
                    textView = KeyboardEnabledTextView()
                }
                configureTextView(textView)
                textView.delegate = context.coordinator
                textView.attributedText = viewModel.originalText

                // Ensure text view supports selection and copy
                textView.isSelectable = true
                textView.isUserInteractionEnabled = true

                viewModel.textView = textView
                return textView
            }

            func updateUIView(_ textView: UXTextView, context _: Context) {
                textView.isAutomaticLinkDetectionEnabled = settings.isLinkDetectionEnabled && viewModel.isLinkDetectionEnabled
            }

            func makeCoordinator() -> Coordinator {
                let coordinator = Coordinator()
                coordinator.onLinkTapped = viewModel.onLinkTapped
                return coordinator
            }
        }

        // Custom UITextView subclass that handles Ctrl+A and Ctrl+C keyboard shortcuts
        class KeyboardEnabledTextView: UITextView {
            override var canBecomeFirstResponder: Bool { true }

            override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
                guard let key = presses.first?.key else {
                    super.pressesBegan(presses, with: event)
                    return
                }

                // Check for Ctrl modifier
                guard key.modifierFlags.contains(.control) else {
                    super.pressesBegan(presses, with: event)
                    return
                }

                let characters = key.charactersIgnoringModifiers.lowercased()

                switch characters {
                case "a":
                    // Ctrl+A: Select All
                    self.selectAll(nil)
                case "c":
                    // Ctrl+C: Copy
                    self.copy(nil)
                default:
                    super.pressesBegan(presses, with: event)
                }
            }
        }

    #elseif os(macOS)

        struct WrappedTextView: NSViewRepresentable {
            let viewModel: RichTextViewModel

            @ObservedObject private var settings = UserSettings.shared

            final class Coordinator: NSObject, NSTextViewDelegate {
                var onLinkTapped: ((URL) -> Bool)?
                var cancellables: [AnyCancellable] = []
                weak var textView: NSTextView?
                var eventMonitor: Any?

                func textView(_: NSTextView, clickedOnLink link: Any, at _: Int) -> Bool {
                    guard let url = link as? URL else {
                        return false
                    }
                    if let onLinkTapped = onLinkTapped, onLinkTapped(url) {
                        return true
                    }
                    return false
                }

                // MARK: - Keyboard Shortcuts

                func setupKeyboardMonitor(for textView: NSTextView) {
                    self.textView = textView
                    // Use a local event monitor for keyDown events
                    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                        guard let self = self, let textView = self.textView else { return event }
                        return self.handleKeyEvent(event, for: textView)
                    }
                }

                func cleanupKeyboardMonitor() {
                    if let monitor = eventMonitor {
                        NSEvent.removeMonitor(monitor)
                        eventMonitor = nil
                    }
                }

                private func handleKeyEvent(_ event: NSEvent, for textView: NSTextView) -> NSEvent? {
                    // Check for Ctrl key modifier
                    guard event.modifierFlags.contains(.control) else {
                        return event
                    }

                    guard let characters = event.charactersIgnoringModifiers?.lowercased() else {
                        return event
                    }

                    switch characters {
                    case "a":
                        // Ctrl+A: Select All
                        textView.selectAll(nil)
                        return nil // Event handled, don't propagate
                    case "c":
                        // Ctrl+C: Copy
                        textView.copy(nil)
                        return nil // Event handled, don't propagate
                    default:
                        return event
                    }
                }

                deinit {
                    cleanupKeyboardMonitor()
                }
            }

            func makeNSView(context: Context) -> NSScrollView {
                let scrollView = UXTextView.scrollableTextView()
                let textView = scrollView.documentView as! UXTextView

                scrollView.hasVerticalScroller = true
                scrollView.autohidesScrollers = true

                configureTextView(textView)
                textView.delegate = context.coordinator

                textView.attributedText = viewModel.originalText

                viewModel.textView = textView

                // Setup keyboard shortcuts
                context.coordinator.setupKeyboardMonitor(for: textView)

                return scrollView
            }

            func updateNSView(_ scrollView: NSScrollView, context _: Context) {
                let textView = scrollView.documentView as! NSTextView
                textView.isAutomaticLinkDetectionEnabled = settings.isLinkDetectionEnabled && viewModel.isLinkDetectionEnabled
            }

            static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
                coordinator.cleanupKeyboardMonitor()
            }

            func makeCoordinator() -> Coordinator {
                let coordinator = Coordinator()
                coordinator.onLinkTapped = viewModel.onLinkTapped
                return coordinator
            }
        }
    #endif

    private func configureTextView(_ textView: UXTextView) {
        textView.isSelectable = true
        textView.isEditable = false
        textView.linkTextAttributes = [
            .underlineStyle: 1,
        ]
        textView.backgroundColor = .clear

        #if os(iOS) || os(visionOS)
            textView.alwaysBounceVertical = true
            textView.autocorrectionType = .no
            textView.autocapitalizationType = .none
            textView.adjustsFontForContentSizeCategory = true
            textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        #endif
        #if os(iOS)
            textView.keyboardDismissMode = .interactive
        #endif

        #if os(macOS)
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.textContainerInset = NSSize(width: 10, height: 10)
        #endif
    }

    private func parseTooltip(_ url: URL) -> (title: String?, message: String)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "pulse",
              components.path == "tooltip",
              let queryItems = components.queryItems,
              let message = queryItems.first(where: { $0.name == "message" })?.value
        else {
            return nil
        }
        let title = queryItems.first(where: { $0.name == "title" })?.value
        return (title: title, message: message)
    }

#endif
