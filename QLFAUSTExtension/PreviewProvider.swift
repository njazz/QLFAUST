//
//  PreviewProvider.swift
//  FAUSTQuickLookPreview
//
//  Created by alex on 16/03/2025.
//

//import QuickLook
//import UniformTypeIdentifiers
//
//class PreviewProvider: QLPreviewProvider {
//    func providePreview(for request: QLFilePreviewRequest, _ handler: @escaping (QLPreviewReply?, Error?) -> Void) {
//        do {
//            // Read the file content
//            let text = try String(contentsOf: request.fileURL, encoding: .utf8)
//            
//            // Generate a basic preview with attributed string
//            let reply = QLPreviewReply(string: text, contentType: .plainText)
//            handler(reply, nil)
//        } catch {
//            handler(nil, error)
//        }
//    }
//}


import Cocoa
import Quartz
import SwiftUI

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    

    /*
     Use a QLPreviewProvider to provide data-based previews.
     
     To set up your extension as a data-based preview extension:

     - Modify the extension's Info.plist by setting
       <key>QLIsDataBasedPreview</key>
       <true/>
     
     - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.

     - Change the NSExtensionPrincipalClass to this class.
       e.g.
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
     
     - Implement providePreview(for:)
     */
    
//    func providePreview(for request: QLFilePreviewRequest, _ handler: @escaping (QLPreviewReply?, Error?) -> Void) {
//            do {
//                let text = try String(contentsOf: request.fileURL, encoding: .utf8)
//                let attributed = FaustSyntaxHighlighter.highlight(text)
//                let size = CGSize(width: 600, height: max(800, estimatedHeight(for: attributed, width: 580)))
//
//                let reply = QLPreviewReply(contextSize: size, isBitmap: true) { context, reply in
//                    // White background
//                    context.setFillColor(NSColor.textBackgroundColor.cgColor)
//                    context.fill(CGRect(origin: .zero, size: size))
//
//                    let textRect = CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20)
//                    attributed.draw(in: textRect)
//                }
//
//                handler(reply, nil)
//            } catch {
//                handler(nil, error)
//            }
//        }
//    
//    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
//            let text = try String(contentsOf: request.fileURL, encoding: .utf8)
//            let attributed = FaustSyntaxHighlighter.highlight(text)
//            let width: CGFloat = 600
//            let height = max(800, estimatedHeight(for: attributed, width: width - 20))
//            let size = CGSize(width: width, height: height)
//
//            return QLPreviewReply(contextSize: size, isBitmap: true) { context, reply in
//                let color1 = NSColor.darkGray
//                let color2 = NSColor.white
//                
//                context.setFillColor(color1.cgColor)
//                context.fill(CGRect(origin: .zero, size: size))
//                
//                context.translateBy(x: 0, y: size.height)
//                context.scaleBy(x: 1.0, y: -1.0)
//
//                let rect = CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20)
//                attributed.draw(in: rect)
//            }
//        }
//
//    private func estimatedHeight(for attributedString: NSAttributedString, width: CGFloat) -> CGFloat {
//        let textContainer = NSTextContainer(containerSize: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
//        let textStorage = NSTextStorage(attributedString: attributedString)
//        let layoutManager = NSLayoutManager()
//
//        layoutManager.addTextContainer(textContainer)
//        textStorage.addLayoutManager(layoutManager)
//
//        layoutManager.glyphRange(for: textContainer)
//        return layoutManager.usedRect(for: textContainer).height + 20 // Padding
//    }
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {

            let contentType = UTType.rtf // RTF supports rich text (font, color, etc.)
            
            let reply = QLPreviewReply(dataOfContentType: contentType, contentSize: CGSize(width: 800, height: 800)) { replyToUpdate in
                
                replyToUpdate.stringEncoding = .utf8
                
                do {
                    // Read Faust source code
                    let source = try String(contentsOf: request.fileURL, encoding: .utf8)
                    
                    // Highlight the source
                    let attributed = FaustSyntaxHighlighter.highlight(source)
                    
                    // Convert to RTF data
                    let rtfData = try attributed.data(from: NSRange(location: 0, length: attributed.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
                    
                    return rtfData
                } catch {
                    return Data("Error".utf8)
                }
            }
            
            return reply
        }
    
//    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
//    
//        //You can create a QLPreviewReply in several ways, depending on the format of the data you want to return.
//        //To return Data of a supported content type:
//        
//        let contentType = UTType.plainText // replace with your data type
//        
//        let reply = QLPreviewReply.init(dataOfContentType: contentType, contentSize: CGSize.init(width: 800, height: 800)) { (replyToUpdate : QLPreviewReply) in
//
//            var data = "";//Data("Hello world".utf8)
//            
//            //setting the stringEncoding for text and html data is optional and defaults to String.Encoding.utf8
//            replyToUpdate.stringEncoding = .utf8
//            
//            //initialize your data here
//            do {
//                // Read the file content
//                data = try String(contentsOf: request.fileURL, encoding: .utf8)
//                
//            } catch {
//                // handler(nil, error)
//                return Data("Error".utf8)
//            }
//            
//            return Data(data.utf8)
//        }
//                
//        return reply
//    }
}
