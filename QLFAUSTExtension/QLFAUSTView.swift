//  Created by alex on 16/03/2025.

import Cocoa
import Quartz
import SwiftUI

import QLFAUST_UI
import UniformTypeIdentifiers

// MARK: -

struct QLFAUSTView: View {
    let fileURL: URL

    @State private var selectedTab = 0

    var body: some View { render }

    var faustString: String
    var jsonString: String
    var svgString: String?
    var error: String

    public init(fileURL: URL, selectedTab: Int = 0) {
        self.fileURL = fileURL
        self.selectedTab = selectedTab

        let file = fileURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        error = Faust_Init(file)
        jsonString = Faust_GetUIJSON()

        svgString = Faust_GenerateSVG(file)

        do {
            faustString = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            faustString = ""
        }
    }

    @ViewBuilder
    private var render: some View {
        TabView(selection: $selectedTab) {
            QLFAUST_UI.PreviewFaustSource(faustString: faustString)
                .tabItem {
                    Text("Source")
                }

            QLFAUST_UI.PreviewSVG(svgString: svgString!)
                .tabItem {
                    Text("SVG")
                }

            QLFAUST_UI.PreviewDSP(jsonString: jsonString)
                .tabItem {
                    Text("DSP")
                }
        }
    }
}
