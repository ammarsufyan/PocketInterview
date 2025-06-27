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
        
        // Allow camera and microphone access
        webView.configuration.userContentController.add(
            context.coordinator,
            name: "sessionHandler"
        )
        
        // FIXED: More conservative session monitoring to prevent auto-close
        let script = WKUserScript(
            source: """
            // Conservative session monitoring for iOS
            let sessionMonitor = {
                sessionStarted: false,
                sessionEnded: false,
                startDetectionDelay: 10000, // Wait 10 seconds before detecting start
                endDetectionDelay: 5000,    // Wait 5 seconds before confirming end
                pageLoadTime: Date.now(),
                
                init() {
                    console.log('🔧 Session monitor initialized at:', this.pageLoadTime);
                    
                    // CONSERVATIVE: Only listen for explicit Tavus events
                    window.addEventListener('message', (event) => {
                        console.log('📨 Received message:', event.data);
                        
                        // Only respond to explicit Tavus session events
                        if (event.data && typeof event.data === 'object') {
                            if (event.data.type === 'tavus_session_started' || 
                                event.data.action === 'session_started' ||
                                (event.data.event && event.data.event === 'conversation_started')) {
                                this.handleSessionStart();
                            } else if (event.data.type === 'tavus_session_ended' || 
                                       event.data.action === 'session_ended' ||
                                       event.data.type === 'call_ended' ||
                                       event.data.type === 'participant_left' ||
                                       (event.data.event && event.data.event === 'conversation_ended')) {
                                this.handleSessionEnd('tavus_event');
                            }
                        }
                    });
                    
                    // CONSERVATIVE: Only monitor visibility if session is confirmed active
                    document.addEventListener('visibilitychange', () => {
                        if (document.hidden && this.sessionStarted && !this.sessionEnded) {
                            console.log('📱 Page hidden during confirmed active session');
                            // Add delay to avoid false positives
                            setTimeout(() => {
                                if (document.hidden && this.sessionStarted && !this.sessionEnded) {
                                    console.log('📱 Confirmed: Page still hidden after delay');
                                    this.handleSessionEnd('ios_background');
                                }
                            }, this.endDetectionDelay);
                        }
                    });
                    
                    // CONSERVATIVE: Delayed auto-detection
                    setTimeout(() => {
                        this.conservativeSessionDetection();
                    }, this.startDetectionDelay);
                },
                
                conservativeSessionDetection() {
                    if (this.sessionStarted) {
                        console.log('🔧 Session already started, skipping detection');
                        return;
                    }
                    
                    console.log('🔍 Starting conservative session detection...');
                    
                    // Look for very specific Tavus indicators
                    const strongIndicators = [
                        '[data-testid*="conversation"]',
                        '[class*="tavus-conversation"]',
                        '[class*="conversation-container"]',
                        '.conversation-view',
                        '#conversation-root'
                    ];
                    
                    let foundStrongIndicator = false;
                    for (const selector of strongIndicators) {
                        if (document.querySelector(selector)) {
                            console.log('🎬 Strong session indicator found:', selector);
                            foundStrongIndicator = true;
                            break;
                        }
                    }
                    
                    // Check for active video with audio
                    const videos = document.querySelectorAll('video');
                    let hasActiveVideo = false;
                    
                    videos.forEach(video => {
                        if (video.readyState >= 2 && !video.paused && video.currentTime > 0) {
                            console.log('🎬 Active video detected:', video);
                            hasActiveVideo = true;
                        }
                    });
                    
                    // Check for microphone/camera access indicators
                    const mediaIndicators = document.querySelectorAll('[class*="media"], [class*="camera"], [class*="microphone"], [class*="audio"]');
                    const hasMediaIndicators = mediaIndicators.length > 0;
                    
                    // CONSERVATIVE: Require multiple indicators
                    const indicatorCount = [foundStrongIndicator, hasActiveVideo, hasMediaIndicators].filter(Boolean).length;
                    
                    if (indicatorCount >= 2) {
                        console.log('🎬 Multiple indicators found, starting session');
                        this.handleSessionStart();
                    } else {
                        console.log('🔍 Insufficient indicators for session start:', {
                            strongIndicator: foundStrongIndicator,
                            activeVideo: hasActiveVideo,
                            mediaIndicators: hasMediaIndicators,
                            count: indicatorCount
                        });
                        
                        // Try again after another delay
                        setTimeout(() => {
                            if (!this.sessionStarted) {
                                this.conservativeSessionDetection();
                            }
                        }, 5000);
                    }
                },
                
                handleSessionStart() {
                    if (this.sessionStarted) {
                        console.log('🔧 Session already started, ignoring duplicate start');
                        return;
                    }
                    
                    // Additional validation before starting
                    const timeSinceLoad = Date.now() - this.pageLoadTime;
                    if (timeSinceLoad < 5000) {
                        console.log('🔧 Too soon after page load, delaying session start');
                        setTimeout(() => this.handleSessionStart(), 2000);
                        return;
                    }
                    
                    this.sessionStarted = true;
                    console.log('🎬 Session started (validated)');
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_started',
                        timestamp: Date.now(),
                        timeSinceLoad: timeSinceLoad
                    });
                },
                
                handleSessionEnd(reason = 'unknown') {
                    if (this.sessionEnded) {
                        console.log('🔧 Session already ended, ignoring duplicate end');
                        return;
                    }
                    
                    if (!this.sessionStarted) {
                        console.log('🔧 Session never started, ignoring end event');
                        return;
                    }
                    
                    this.sessionEnded = true;
                    console.log('🏁 Session ended (validated), reason:', reason);
                    
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_ended',
                        reason: reason,
                        timestamp: Date.now()
                    });
                }
            };
            
            // Initialize session monitor when DOM is ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => {
                    console.log('📄 DOM loaded, initializing session monitor');
                    sessionMonitor.init();
                });
            } else {
                console.log('📄 DOM already loaded, initializing session monitor');
                sessionMonitor.init();
            }
            
            // Global error handler
            window.addEventListener('error', (event) => {
                console.error('🚨 JavaScript error:', event.error);
            });
            
            console.log('✅ Conservative session monitoring initialized');
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
        private var pageLoadTime = Date()
        
        init(_ parent: TavusWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 WebView started loading")
            pageLoadTime = Date()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Tavus WebView loaded successfully")
            
            // CONSERVATIVE: Minimal JavaScript injection
            let js = """
            console.log('📱 Tavus WebView ready for iOS');
            console.log('🔧 Page URL:', window.location.href);
            console.log('🔧 Page title:', document.title);
            
            // Log page content for debugging
            setTimeout(() => {
                console.log('🔧 Page content loaded');
                console.log('🔧 Body classes:', document.body.className);
                console.log('🔧 Video elements:', document.querySelectorAll('video').length);
            }, 2000);
            """
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ JavaScript injection error: \(error)")
                } else {
                    print("✅ Minimal JavaScript injected successfully")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Tavus WebView failed to load: \(error)")
        }
        
        // CONSERVATIVE: Only handle explicit navigation away
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Only trigger session end for user-initiated navigation
            if sessionStarted && !sessionEnded && 
               navigationAction.navigationType == .linkActivated {
                print("🔄 User navigated away during active session")
                handleSessionEnd(reason: "user_navigation")
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
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
            let timeSinceLoad = body["timeSinceLoad"] as? Double
            
            print("📨 Received session message: \(action), reason: \(reason)")
            
            DispatchQueue.main.async {
                switch action {
                case "session_started":
                    // CONSERVATIVE: Additional validation
                    let currentTime = Date().timeIntervalSince(self.pageLoadTime)
                    if currentTime < 5.0 {
                        print("🔧 Session start too soon after page load (\(currentTime)s), ignoring")
                        return
                    }
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
            guard !sessionStarted else { 
                print("🔧 Session already started, ignoring duplicate")
                return 
            }
            
            sessionStarted = true
            print("🎬 Tavus session started (iOS) - Validated")
            parent.onSessionStart()
        }
        
        private func handleSessionEnd(reason: String) {
            guard sessionStarted && !sessionEnded else { 
                print("🔧 Invalid session end state - started: \(sessionStarted), ended: \(sessionEnded)")
                return 
            }
            
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