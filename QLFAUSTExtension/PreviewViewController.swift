//  Created by alex on 16/03/2025.

import Cocoa
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {
    override func loadView() {
        view = NSView()
    }

    var gestureRecognizer: NSClickGestureRecognizer?

    func preparePreviewOfFile(at url: URL) async throws {
        let swiftUIView = QLFAUSTView(fileURL: url)
            .frame(minWidth: 100, idealWidth: .infinity, maxWidth: .infinity)
            .frame(minHeight: 100, idealHeight: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))

        let hostingView = NSHostingView(rootView: swiftUIView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 800, height: 600)

        view.setFrameSize(hostingView.frame.size)
        view.wantsLayer = false

        view.addSubview(hostingView, positioned: .above, relativeTo: nil)

        hostingView.frame = view.bounds
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame.origin = CGPoint(x: 0, y: 0)

        hostingView.wantsLayer = true
        hostingView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        hostingView.setAccessibilityRole(.group)

        view.window?.makeFirstResponder(hostingView)
    }
}
