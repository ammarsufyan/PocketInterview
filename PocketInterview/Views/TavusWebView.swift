import SwiftUI
import WebKit
import SafariServices

struct TavusWebView: UIViewRepresentable {
    let url: String
    let onSessionStart: () -> Void
    let onSessionEnd: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // PERFORMANCE: Optimize configuration for better performance
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // PERFORMANCE: Disable unnecessary features to reduce overhead
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences.javaScriptEnabled = true
        
        // PERFORMANCE: Optimize process pool for memory efficiency
        configuration.processPool = WKProcessPool()
        
        // PERFORMANCE: Disable data detection to reduce CPU usage
        configuration.dataDetectorTypes = []
        
        // PERFORMANCE: Optimize user content controller
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "sessionHandler")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // PERFORMANCE: Disable scroll bounce and zoom to reduce GPU usage
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        // PERFORMANCE: Disable back/forward navigation
        webView.allowsBackForwardNavigationGestures = false
        
        // PERFORMANCE: Set background color to reduce rendering overhead
        webView.backgroundColor = UIColor.black
        webView.isOpaque = true
        
        // PERFORMANCE: Minimal JavaScript injection - only essential monitoring
        let minimalScript = WKUserScript(
            source: """
            // MINIMAL: Only essential session monitoring
            let sessionMonitor = {
                sessionStarted: false,
                sessionEnded: false,
                checkInterval: null,
                
                init() {
                    console.log('📱 Minimal session monitor started');
                    
                    // Listen for Tavus events only
                    window.addEventListener('message', (event) => {
                        if (event.data?.type === 'conversation_started' || 
                            event.data?.event === 'conversation_started') {
                            this.handleSessionStart();
                        }
                        if (event.data?.type === 'conversation_ended' || 
                            event.data?.event === 'conversation_ended') {
                            this.handleSessionEnd();
                        }
                    });
                    
                    // Simple periodic check - reduced frequency
                    this.checkInterval = setInterval(() => {
                        this.checkSession();
                    }, 10000); // Check every 10 seconds instead of 5
                },
                
                checkSession() {
                    if (this.sessionStarted || this.sessionEnded) return;
                    
                    const videos = document.querySelectorAll('video');
                    if (videos.length > 0 && videos[0].readyState >= 2 && !videos[0].paused) {
                        this.handleSessionStart();
                    }
                },
                
                handleSessionStart() {
                    if (this.sessionStarted) return;
                    this.sessionStarted = true;
                    
                    if (this.checkInterval) {
                        clearInterval(this.checkInterval);
                        this.checkInterval = null;
                    }
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_started'
                    });
                },
                
                handleSessionEnd() {
                    if (this.sessionEnded || !this.sessionStarted) return;
                    this.sessionEnded = true;
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_ended'
                    });
                }
            };
            
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => sessionMonitor.init());
            } else {
                sessionMonitor.init();
            }
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        webView.configuration.userContentController.addUserScript(minimalScript)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let newURL = URL(string: url) else { return }
        
        // PERFORMANCE: Only load if URL is different
        if webView.url != newURL {
            let request = URLRequest(url: newURL)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let parent: TavusWebView
        private var sessionStarted = false
        private var sessionEnded = false
        
        init(_ parent: TavusWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 WebView loading started")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView loaded successfully")
            
            // PERFORMANCE: Minimal post-load JavaScript
            let optimizationJS = """
            // Disable unnecessary features for performance
            document.addEventListener('contextmenu', e => e.preventDefault());
            document.addEventListener('selectstart', e => e.preventDefault());
            """
            
            webView.evaluateJavaScript(optimizationJS) { _, error in
                if let error = error {
                    print("⚠️ Optimization JS error: \(error)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed to load: \(error)")
        }
        
        // PERFORMANCE: Strict navigation control
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Block unnecessary navigation during session
            if sessionStarted && !sessionEnded {
                if navigationAction.navigationType == .linkActivated || 
                   navigationAction.navigationType == .reload {
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            if sessionStarted && !sessionEnded && message.lowercased().contains("leave") {
                handleSessionEnd()
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "sessionHandler",
                  let body = message.body as? [String: Any],
                  let action = body["action"] as? String else {
                return
            }
            
            DispatchQueue.main.async {
                switch action {
                case "session_started":
                    self.handleSessionStart()
                case "session_ended":
                    self.handleSessionEnd()
                default:
                    break
                }
            }
        }
        
        // MARK: - Session Management
        
        private func handleSessionStart() {
            guard !sessionStarted else { return }
            sessionStarted = true
            parent.onSessionStart()
        }
        
        private func handleSessionEnd() {
            guard sessionStarted && !sessionEnded else { return }
            sessionEnded = true
            parent.onSessionEnd()
        }
    }
}

// MARK: - Safari Alternative View

struct SafariWebView: UIViewControllerRepresentable {
    let url: String
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        guard let url = URL(string: url) else {
            fatalError("Invalid URL")
        }
        
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = false
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        safari.preferredBarTintColor = UIColor.systemBackground
        safari.preferredControlTintColor = UIColor.systemBlue
        
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariWebView
        
        init(_ parent: SafariWebView) {
            self.parent = parent
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.onDismiss()
        }
    }
}

#Preview {
    TavusWebView(
        url: "https://tavus.io/conversations/demo",
        onSessionStart: {
            print("Session started")
        },
        onSessionEnd: {
            print("Session ended")
        }
    )
}