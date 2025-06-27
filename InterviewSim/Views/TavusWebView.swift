//
//  TavusWebView.swift
//  InterviewSim
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
        
        // Enable camera and microphone
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // FIXED: Prevent automatic reloads
        webView.allowsBackForwardNavigationGestures = false
        
        // Allow camera and microphone access
        webView.configuration.userContentController.add(
            context.coordinator,
            name: "sessionHandler"
        )
        
        // FIXED: Much simpler and more stable session monitoring
        let script = WKUserScript(
            source: """
            // STABLE: Simplified session monitoring to prevent reloads
            const sessionMonitor = {
                sessionStarted: false,
                sessionEnded: false,
                pageLoadTime: Date.now(),
                startCheckInterval: null,
                
                init() {
                    console.log('🔧 Stable session monitor initialized');
                    
                    // STABLE: Listen for Tavus-specific events only
                    window.addEventListener('message', (event) => {
                        if (event.data && typeof event.data === 'object') {
                            const data = event.data;
                            
                            // Check for conversation started events
                            if (data.type === 'conversation_started' || 
                                data.event === 'conversation_started' ||
                                data.action === 'session_started') {
                                this.handleSessionStart();
                            }
                            
                            // Check for conversation ended events
                            if (data.type === 'conversation_ended' || 
                                data.event === 'conversation_ended' ||
                                data.type === 'call_ended' ||
                                data.action === 'session_ended') {
                                this.handleSessionEnd('tavus_event');
                            }
                        }
                    });
                    
                    // STABLE: Simple periodic check instead of complex DOM monitoring
                    this.startCheckInterval = setInterval(() => {
                        this.checkSessionState();
                    }, 5000); // Check every 5 seconds
                    
                    // REMOVED: Visibility change listener to prevent reload issues
                },
                
                checkSessionState() {
                    if (this.sessionStarted || this.sessionEnded) {
                        return; // Already handled
                    }
                    
                    // Simple check for active video elements
                    const videos = document.querySelectorAll('video');
                    let hasActiveVideo = false;
                    
                    videos.forEach(video => {
                        if (video.readyState >= 2 && !video.paused && video.currentTime > 0) {
                            hasActiveVideo = true;
                        }
                    });
                    
                    // Check if enough time has passed since page load
                    const timeSinceLoad = Date.now() - this.pageLoadTime;
                    
                    if (hasActiveVideo && timeSinceLoad > 10000) { // 10 seconds minimum
                        console.log('🎬 Active video detected, starting session');
                        this.handleSessionStart();
                    }
                },
                
                handleSessionStart() {
                    if (this.sessionStarted) return;
                    
                    this.sessionStarted = true;
                    console.log('🎬 Session started');
                    
                    // Clear the check interval
                    if (this.startCheckInterval) {
                        clearInterval(this.startCheckInterval);
                        this.startCheckInterval = null;
                    }
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_started',
                        timestamp: Date.now()
                    });
                },
                
                handleSessionEnd(reason = 'unknown') {
                    if (this.sessionEnded || !this.sessionStarted) return;
                    
                    this.sessionEnded = true;
                    console.log('🏁 Session ended, reason:', reason);
                    
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
            
            // STABLE: Prevent page reloads
            window.addEventListener('beforeunload', (event) => {
                console.log('🚫 Preventing page unload');
                event.preventDefault();
                return '';
            });
            
            console.log('✅ Stable session monitoring initialized');
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        webView.configuration.userContentController.addUserScript(script)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // FIXED: Only load if URL is different to prevent unnecessary reloads
        guard let newURL = URL(string: url) else { return }
        
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
        private var isLoading = false
        
        init(_ parent: TavusWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 WebView started loading")
            isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Tavus WebView loaded successfully")
            isLoading = false
            
            // STABLE: Minimal JavaScript injection
            let js = """
            console.log('📱 Tavus WebView ready');
            console.log('🔧 URL:', window.location.href);
            """
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ JavaScript error: \(error)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed to load: \(error)")
            isLoading = false
        }
        
        // FIXED: Prevent unwanted navigation that causes reloads
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Allow initial load
            if !isLoading && navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }
            
            // FIXED: Block user-initiated navigation during session to prevent reloads
            if sessionStarted && !sessionEnded {
                if navigationAction.navigationType == .linkActivated || 
                   navigationAction.navigationType == .formSubmitted ||
                   navigationAction.navigationType == .reload {
                    print("🚫 Blocking navigation during active session to prevent reload")
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            print("🎥 Media permission requested: \(type)")
            decisionHandler(.grant)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            print("🔔 Alert: \(message)")
            completionHandler()
        }
        
        // FIXED: Handle JavaScript confirm dialogs (like "Are you sure you want to leave?")
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            print("❓ Confirm dialog: \(message)")
            
            // If it's a leave confirmation during active session, handle it properly
            if sessionStarted && !sessionEnded && message.lowercased().contains("leave") {
                print("🚪 User wants to leave during active session")
                handleSessionEnd(reason: "user_leave")
                completionHandler(true) // Allow leaving
            } else {
                completionHandler(false) // Block other confirmations that might cause reload
            }
        }
        
        func webViewDidClose(_ webView: WKWebView) {
            print("🚪 WebView closed")
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
            
            print("📨 Session message: \(action)")
            
            DispatchQueue.main.async {
                switch action {
                case "session_started":
                    self.handleSessionStart()
                case "session_ended":
                    self.handleSessionEnd(reason: reason)
                default:
                    print("🔄 Unknown action: \(action)")
                }
            }
        }
        
        // MARK: - Session Management
        
        private func handleSessionStart() {
            guard !sessionStarted else { return }
            
            sessionStarted = true
            print("🎬 Session started (iOS)")
            parent.onSessionStart()
        }
        
        private func handleSessionEnd(reason: String) {
            guard sessionStarted && !sessionEnded else { return }
            
            sessionEnded = true
            print("🏁 Session ended (iOS) - Reason: \(reason)")
            parent.onSessionEnd()
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