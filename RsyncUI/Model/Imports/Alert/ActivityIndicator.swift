//
//  File.swift
//
//
//  Created by אילי זוברמן on 14/02/2021.
//

import SwiftUI

#if os(macOS)
    @available(macOS 11, *)
    struct ActivityIndicator: NSViewRepresentable {
        func makeNSView(context: NSViewRepresentableContext<ActivityIndicator>) -> NSProgressIndicator {
            let nsView = NSProgressIndicator()

            nsView.isIndeterminate = true
            nsView.style = .spinning
            nsView.startAnimation(context)

            return nsView
        }

        func updateNSView(_: NSProgressIndicator, context _: NSViewRepresentableContext<ActivityIndicator>) {}
    }
#else
    @available(iOS 13, *)
    struct ActivityIndicator: UIViewRepresentable {
        func makeUIView(context _: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
            let progressView = UIActivityIndicatorView(style: .large)
            progressView.startAnimating()

            return progressView
        }

        func updateUIView(_: UIActivityIndicatorView, context _: UIViewRepresentableContext<ActivityIndicator>) {}
    }
#endif
