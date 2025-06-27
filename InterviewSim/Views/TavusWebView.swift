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
        
        // Enable media playbook
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Enable camera and microphone
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Allow camera and microphone access
        webView.configuration.userContentController.add(
            context.coordinator,
            name: "sessionHandler"
        )
        
        // ENHANCED: Inject JavaScript to handle session events and iOS controls
        let script = WKUserScript(
            source: """
            // Enhanced session monitoring for iOS
            let sessionMonitor = {
                sessionStarted: false,
                sessionEnded: false,
                
                // Monitor for Tavus session events
                init() {
                    // Listen for Tavus-specific events
                    window.addEventListener('message', (event) => {
                        console.log('📨 Received message:', event.data);
                        
                        if (event.data.type === 'tavus_session_started' || 
                            event.data.action === 'session_started' ||
                            (event.data.event && event.data.event.includes('started'))) {
                            this.handleSessionStart();
                        } else if (event.data.type === 'tavus_session_ended' || 
                                   event.data.action === 'session_ended' ||
                                   event.data.type === 'call_ended' ||
                                   event.data.type === 'participant_left' ||
                                   (event.data.event && event.data.event.includes('ended'))) {
                            this.handleSessionEnd();
                        }
                    });
                    
                    // Monitor for page visibility changes (iOS backgrounding)
                    document.addEventListener('visibilitychange', () => {
                        if (document.hidden && this.sessionStarted && !this.sessionEnded) {
                            console.log('📱 Page hidden during active session - potential iOS cancel');
                            setTimeout(() => {
                                if (document.hidden) {
                                    this.handleSessionEnd('ios_cancel');
                                }
                            }, 1000);
                        }
                    });
                    
                    // Monitor for beforeunload (page closing)
                    window.addEventListener('beforeunload', () => {
                        if (this.sessionStarted && !this.sessionEnded) {
                            console.log('🚪 Page unloading during active session');
                            this.handleSessionEnd('page_unload');
                        }
                    });
                    
                    // Monitor for pagehide (iOS specific)
                    window.addEventListener('pagehide', () => {
                        if (this.sessionStarted && !this.sessionEnded) {
                            console.log('📱 Page hide during active session - iOS specific');
                            this.handleSessionEnd('ios_pagehide');
                        }
                    });
                    
                    // Auto-detect session start based on DOM changes
                    this.detectSessionStart();
                },
                
                detectSessionStart() {
                    const checkForSession = () => {
                        if (this.sessionStarted) return;
                        
                        // Look for various indicators of an active session
                        const indicators = [
                            '[data-tavus-session]',
                            '.tavus-conversation',
                            '.tavus-video',
                            '[class*="conversation"]',
                            '[class*="video-call"]',
                            'video[autoplay]',
                            '.call-container',
                            '.meeting-container'
                        ];
                        
                        for (const selector of indicators) {
                            if (document.querySelector(selector)) {
                                console.log('🎬 Session detected via selector:', selector);
                                this.handleSessionStart();
                                return;
                            }
                        }
                        
                        // Check for video elements
                        const videos = document.querySelectorAll('video');
                        if (videos.length > 0) {
                            for (const video of videos) {
                                if (!video.paused || video.readyState > 0) {
                                    console.log('🎬 Session detected via active video');
                                    this.handleSessionStart();
                                    return;
                                }
                            }
                        }
                        
                        // Check for text content indicating active session
                        const bodyText = document.body.innerText.toLowerCase();
                        if (bodyText.includes('conversation') || 
                            bodyText.includes('connected') || 
                            bodyText.includes('speaking') ||
                            bodyText.includes('listening')) {
                            console.log('🎬 Session detected via text content');
                            this.handleSessionStart();
                            return;
                        }
                    };
                    
                    // Check immediately and then periodically
                    checkForSession();
                    const interval = setInterval(() => {
                        checkForSession();
                        if (this.sessionStarted) {
                            clearInterval(interval);
                        }
                    }, 2000);
                    
                    // Stop checking after 30 seconds
                    setTimeout(() => clearInterval(interval), 30000);
                },
                
                handleSessionStart() {
                    if (this.sessionStarted) return;
                    
                    this.sessionStarted = true;
                    console.log('🎬 Session started');
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_started',
                        timestamp: Date.now()
                    });
                },
                
                handleSessionEnd(reason = 'unknown') {
                    if (this.sessionEnded) return;
                    
                    this.sessionEnded = true;
                    console.log('🏁 Session ended, reason:', reason);
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_ended',
                        reason: reason,
                        timestamp: Date.now()
                    });
                }
            };
            
            // Initialize session monitor
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => sessionMonitor.init());
            } else {
                sessionMonitor.init();
            }
            
            // Global error handler
            window.addEventListener('error', (event) => {
                console.error('🚨 JavaScript error:', event.error);
            });
            
            console.log('✅ Enhanced session monitoring initialized');
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        webView.configuration.userContentController.addUserScript(script)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: url) else { return }
        
        let request = URLRequest(url: url)
        webView.load(request)
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
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Tavus WebView loaded successfully")
            
            // Additional JavaScript injection after page load
            let js = """
            console.log('📱 Tavus WebView ready for iOS');
            
            // Force session detection after a delay
            setTimeout(() => {
                if (typeof sessionMonitor !== 'undefined') {
                    sessionMonitor.detectSessionStart();
                }
            }, 3000);
            """
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ JavaScript injection error: \(error)")
                } else {
                    print("✅ Additional JavaScript injected successfully")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Tavus WebView failed to load: \(error)")
        }
        
        // ENHANCED: Handle navigation actions (back button, etc.)
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Check if user is navigating away during active session
            if sessionStarted && !sessionEnded && navigationAction.navigationType == .other {
                print("🔄 Navigation detected during active session")
                handleSessionEnd(reason: "navigation_away")
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            // Grant camera and microphone permissions
            print("🎥 Media capture permission requested for: \(type)")
            decisionHandler(.grant)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            print("🔔 Tavus Alert: \(message)")
            completionHandler()
        }
        
        // Handle window close events
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
            let timestamp = body["timestamp"] as? Double ?? Date().timeIntervalSince1970 * 1000
            
            DispatchQueue.main.async {
                switch action {
                case "session_started":
                    self.handleSessionStart()
                case "session_ended":
                    self.handleSessionEnd(reason: reason)
                default:
                    print("🔄 Unknown Tavus action: \(action)")
                }
            }
        }
        
        // MARK: - Session Management
        
        private func handleSessionStart() {
            guard !sessionStarted else { return }
            
            sessionStarted = true
            print("🎬 Tavus session started (iOS)")
            parent.onSessionStart()
        }
        
        private func handleSessionEnd(reason: String) {
            guard sessionStarted && !sessionEnded else { return }
            
            sessionEnded = true
            print("🏁 Tavus session ended (iOS) - Reason: \(reason)")
            parent.onSessionEnd()
        }
    }
}

// MARK: - Preview

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