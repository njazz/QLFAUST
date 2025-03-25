//
//  DSPPreview.swift
//  QLFAUST
//
//  Created by alex on 24/03/2025.
//

import SwiftUI

import FaustSwiftUI

public struct PreviewDSP<ViewModelT: FaustUIValueBinding>: View {
    @StateObject var viewModel: ViewModelT
    
    let jsonString: String

    let ui: [FaustUI]

    var error: String

    public init(jsonString: String, viewModel: ViewModelT) {
        self.jsonString = jsonString
        
        _viewModel = StateObject(wrappedValue: viewModel)
        
        do {
            let jsonData = Data(self.jsonString.utf8)

            let ui = try JSONDecoder().decode(FaustUIJSON.self, from: jsonData)
            self.ui = ui.ui!
            self.error = ""
        } catch let err {
            self.ui = []
            self.error = "exception: " + err.localizedDescription
        }        
    }

    public var body: some View { render }

    @ViewBuilder
    private var render: some View {
        VStack {
            Text(error)

            FaustUIView(ui: ui, viewModel: viewModel)
                .frame(minWidth:320, minHeight: 240)
        }
    }
}

// MARK: -

struct PreviewDSP_Preview: PreviewProvider {
    static var previews: some View { PreviewDSP(jsonString: "{\"ui\":[]}", viewModel:FaustUIViewModel()) }
}
