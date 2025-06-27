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
        
        // Inject JavaScript to handle session events
        let script = WKUserScript(
            source: """
            // Listen for Tavus session events
            window.addEventListener('message', function(event) {
                if (event.data.type === 'tavus_session_started') {
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_started'
                    });
                } else if (event.data.type === 'tavus_session_ended') {
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_ended'
                    });
                }
            });
            
            // Also listen for page visibility changes
            document.addEventListener('visibilitychange', function() {
                if (document.hidden) {
                    console.log('Page hidden');
                } else {
                    console.log('Page visible');
                }
            });
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
        
        init(_ parent: TavusWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Tavus WebView loaded successfully")
            
            // Inject additional JavaScript if needed
            let js = """
            console.log('Tavus WebView ready');
            
            // Auto-start session detection
            setTimeout(function() {
                if (document.querySelector('[data-tavus-session]') || 
                    document.querySelector('.tavus-conversation') ||
                    document.body.innerText.includes('conversation')) {
                    window.webkit.messageHandlers.sessionHandler.postMessage({
                        action: 'session_started'
                    });
                }
            }, 2000);
            """
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ JavaScript injection error: \(error)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Tavus WebView failed to load: \(error)")
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            // Grant camera and microphone permissions
            decisionHandler(.grant)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            print("🔔 Tavus Alert: \(message)")
            completionHandler()
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
                    print("🎬 Tavus session started")
                    self.parent.onSessionStart()
                case "session_ended":
                    print("🏁 Tavus session ended")
                    self.parent.onSessionEnd()
                default:
                    print("🔄 Unknown Tavus action: \(action)")
                }
            }
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