//
//  FAUSTViewerApp.swift
//  FAUSTViewer
//
//  Created by alex on 26/03/2025.
//

import SwiftUI

import QLFAUST_UI
import UniformTypeIdentifiers

// Define the document model
struct MyDocument:  FileDocument {
    init() {}

    // Required initializer for FileDocument
    static var readableContentTypes: [UTType] { [.plainText] }

    init(configuration: ReadConfiguration) throws {

    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Since we are not saving the document, we return an empty file wrapper
        return FileWrapper()//(regularFileWithContents: Data())
    }
}

// Define the main content view of the document
struct DocumentView: View {
//    @Binding var document: MyDocument
    var fileURL: URL?

    var body: some View {
        VStack {
            if let fileURL = fileURL {
                QLFAUSTView(fileURL: fileURL)
                    .frame(minHeight: 300, maxHeight: .infinity)

            } else {
                Text("No file selected")
                    .font(.headline)
                    .padding()
            }

        }
        .frame(minHeight: 800, maxHeight: .infinity)
    }
}

// Define the main app entry point
@main
struct MyApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MyDocument()) { file in
            DocumentView(fileURL: file.fileURL)
        }
    }
}
