//
//  FaustSourcePreview.swift
//  QLFAUST
//
//  Created by alex on 24/03/2025.
//

import SwiftUI

import RichTextKit

public struct PreviewFaustSource: View {
    public let source: String

    @State private var ready: Bool

    @State var attributedString: NSAttributedString

    public init(faustString: String) {
        source = faustString

        attributedString = NSAttributedString(string: "Loading ...")

        ready = false
    }

    public var body: some View {
        VStack {
            if !self.ready {
                Text("Loading ...")
            } else {
                RichTextViewer(attributedString)
            }
        }
        .onAppear {
            loadPreview()
        }
        .frame(minWidth: 320, minHeight: 240)
    }

    private func loadPreview() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let highlighted = FaustSyntaxHighlighter.highlight(source)

                let rtfData = try highlighted.data(from: NSRange(location: 0, length: highlighted.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])

                let result = try NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)

                print(result.string)

                self.attributedString = result
                self.ready = true

            } catch {
                self.attributedString = NSAttributedString(string: "Error loading file.")
            }
        }
    }
}

// MARK: -

struct PreviewFaustSource_Preview: PreviewProvider {
    static var previews: some View {
        PreviewFaustSource(faustString: #"""
        process = _;
        """#)
    }
}
