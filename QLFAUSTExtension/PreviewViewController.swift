//  Created by alex on 16/03/2025.

import Cocoa
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {
    override func loadView() {
        // Create a basic NSView as the root view
        view = NSView()
    }

    func preparePreviewOfFile(at url: URL) async throws {
        // Create the SwiftUI view
        let swiftUIView = QLFAUSTView(fileURL: url)
            .frame(minWidth: 100, idealWidth: .infinity, maxWidth: .infinity)
            .frame(minHeight: 100, idealHeight: .infinity, maxHeight: .infinity)

        // Embed it into an NSHostingView
        let hostingView = NSHostingView(rootView: swiftUIView)

        // Set the desired size for the hosting view (800x600)
        hostingView.frame = CGRect(x: 0, y: 0, width: 800, height: 600)

        // Optionally: Resize the parent view to match the hosting view size
        view.setFrameSize(hostingView.frame.size)

        // Add the hosting view to the controller's view
        view.addSubview(hostingView)

        hostingView.frame = view.bounds

        // Set autoresizing mask for proper resizing behavior
        hostingView.autoresizingMask = [.width, .height]

        hostingView.frame.origin = CGPoint(x: 0, y: 0)
    }
}
