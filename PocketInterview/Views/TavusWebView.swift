//
//  TavusWebView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI
import WebKit

struct TavusWebView: UIViewRepresentable {
    let url: String
    let onSessionStart: () -> Void
    let onSessionEnd: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Enable media playback
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Optimize memory usage
        configuration.websiteDataStore = .nonPersistent()
        configuration.processPool = WKProcessPool()
        
        // Optimize performance
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences = preferences
        
        // Reduce memory footprint
        configuration.limitsNavigationsToAppBoundDomains = false
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Prevent automatic reloads
        webView.allowsBackForwardNavigationGestures = false
        
        // Add message handler for session events
        webView.configuration.userContentController.add(
            context.coordinator,
            name: "sessionHandler"
        )
        
        // Inject minimal JavaScript for session monitoring
        let script = WKUserScript(
            source: """
            // Simplified session monitoring
            const sessionMonitor = {
                sessionStarted: false,
                sessionEnded: false,
                
                init() {
                    console.log('Session monitor initialized');
                    
                    // Listen for Tavus-specific events
                    window.addEventListener('message', (event) => {
                        if (event.data && typeof event.data === 'object') {
                            const data = event.data;
                            
                            if (data.type === 'conversation_started' || 
                                data.event === 'conversation_started' ||
                                data.action === 'session_started') {
                                this.handleSessionStart();
                            }
                            
                            if (data.type === 'conversation_ended' || 
                                data.event === 'conversation_ended' ||
                                data.type === 'call_ended' ||
                                data.action === 'session_ended') {
                                this.handleSessionEnd('tavus_event');
                            }
                        }
                    });
                    
                    // Check for active video elements periodically
                    setInterval(() => this.checkVideoElements(), 5000);
                    
                    // Prevent page reloads
                    window.addEventListener('beforeunload', (event) => {
                        event.preventDefault();
                        return '';
                    });
                },
                
                checkVideoElements() {
                    if (this.sessionStarted || this.sessionEnded) return;
                    
                    const videos = document.querySelectorAll('video');
                    for (const video of videos) {
                        if (video.readyState >= 2 && !video.paused && video.currentTime > 0) {
                            this.handleSessionStart();
                            break;
                        }
                    }
                },
                
                handleSessionStart() {
                    if (this.sessionStarted) return;
                    
                    this.sessionStarted = true;
                    console.log('Session started');
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_started',
                        timestamp: Date.now()
                    });
                },
                
                handleSessionEnd(reason = 'unknown') {
                    if (this.sessionEnded || !this.sessionStarted) return;
                    
                    this.sessionEnded = true;
                    console.log('Session ended, reason:', reason);
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_ended',
                        reason: reason,
                        timestamp: Date.now()
                    });
                }
            };
            
            // Initialize when DOM is ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => {
                    sessionMonitor.init();
                });
            } else {
                sessionMonitor.init();
            }
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        webView.configuration.userContentController.addUserScript(script)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load if URL is different to prevent unnecessary reloads
        guard let newURL = URL(string: url) else { return }
        
        if webView.url != newURL {
            let request = URLRequest(url: newURL, cachePolicy: .returnCacheDataElseLoad)
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
        private var isLoading = false
        
        init(_ parent: TavusWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            
            // Minimal JavaScript injection after page load
            let js = "console.log('WebView loaded successfully');"
            
            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("JavaScript error: \(error.localizedDescription)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            print("WebView failed to load: \(error.localizedDescription)")
        }
        
        // Prevent unwanted navigation that causes reloads
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Allow initial load
            if !isLoading && navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }
            
            // Block user-initiated navigation during session to prevent reloads
            if sessionStarted && !sessionEnded {
                if navigationAction.navigationType == .linkActivated || 
                   navigationAction.navigationType == .formSubmitted ||
                   navigationAction.navigationType == .reload {
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            // Grant camera/microphone permissions automatically
            decisionHandler(.grant)
        }
        
        // Handle JavaScript alerts without showing UI
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            print("Alert: \(message)")
            completionHandler()
        }
        
        // Handle JavaScript confirm dialogs
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            // If it's a leave confirmation during active session, handle it properly
            if sessionStarted && !sessionEnded && message.lowercased().contains("leave") {
                handleSessionEnd(reason: "user_leave")
                completionHandler(true) // Allow leaving
            } else {
                completionHandler(false) // Block other confirmations
            }
        }
        
        func webViewDidClose(_ webView: WKWebView) {
            if sessionStarted && !sessionEnded {
                handleSessionEnd(reason: "webview_closed")
            }
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "sessionHandler",
                  let body = message.body as? [String: Any],
                  let action = body["action"] as? String else {
                return
            }
            
            let reason = body["reason"] as? String ?? "unknown"
            
            DispatchQueue.main.async {
                switch action {
                case "session_started":
                    self.handleSessionStart()
                case "session_ended":
                    self.handleSessionEnd(reason: reason)
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
        
        private func handleSessionEnd(reason: String) {
            guard sessionStarted && !sessionEnded else { return }
            
            sessionEnded = true
            parent.onSessionEnd()
        }
    }
}