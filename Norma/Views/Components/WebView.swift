//
//  WebView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

struct WebViewSheet: View {
    let url: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if let webURL = URL(string: url) {
                    WebView(url: webURL)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .center) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(UIColor.systemBackground).opacity(0.8))
                                    .onAppear {
                                        // Simple timer to hide loading after a reasonable time
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            withAnimation {
                                                isLoading = false
                                            }
                                        }
                                    }
                            }
                        }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text("Unable to load content")
                            .font(.headline)

                        Text("The requested page could not be loaded.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    WebViewSheet(
        url: "https://www.apple.com",
        title: "Preview"
    )
}
