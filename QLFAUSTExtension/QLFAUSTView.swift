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

    @State private var faustString = ""
    @State private var jsonString = "[]"
    @State private var svgString: String? = nil
    @State private var error = ""

    @State private var faustDspObject: FaustDSPObject?
    @State private var audioEngine: AudioEngine?

    public init(fileURL: URL, selectedTab: Int = 0) {
        self.fileURL = fileURL
        self.selectedTab = selectedTab

        let file = fileURL.absoluteString.replacingOccurrences(of: "file://", with: "")

        var errorString: NSString?

        if let result = FaustDSPObject(path: file, error: &errorString) {
            _jsonString = State(initialValue: result.getUIJSON())
            _svgString = State(initialValue: result.getSVG())
            _faustDspObject = State(initialValue: result)
            _error = State(initialValue: "")
            _audioEngine = State(initialValue: AudioEngine(faustDspObject!))
        } else {
            _jsonString = State(initialValue: "[]")
            _faustString = State(initialValue: "")
            _svgString = State(initialValue: nil)
            _faustDspObject = State(initialValue: nil)
            _audioEngine = State(initialValue: nil)
            _error = State(initialValue: errorString! as String)
        }

        do {
            _faustString = State(initialValue: try String(contentsOf: fileURL, encoding: .utf8))
        } catch {
            _faustString = State(initialValue: "")
        }
    }

    public var body: some View { render }
    
    @ViewBuilder
    private var render: some View {
        TabView(selection: $selectedTab) {
            QLFAUST_UI.PreviewFaustSource(faustString: faustString)
                .tabItem {
                    Text("Source")
                }

            if let svgString = svgString {
                QLFAUST_UI.PreviewSVG(svgString: svgString)
                    .tabItem {
                        Text("SVG")
                    }
            } else {
                Text("No SVG available")
                    .tabItem {
                        Text("SVG")
                    }
            }

            VStack {
                VStack {
                    HStack() {
                        if let engine = audioEngine {
                            Button(action: {
                                engine.isRunning ? engine.stop() : engine.start()
                            }) {
                                Text(engine.isRunning ? "Stop Audio" : "Start Audio")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 30)
                                    .background(engine.isRunning ? Color.red : Color.green)
                                    .foregroundColor(.white)
//                                    .cornerRadius(10)
                                    .animation(.easeInOut(duration: 0.2), value: engine.isRunning)
                            }.frame(width:120, height: 60)
                            
                            Text(engine.statusMessage)
//                                .foregroundColor(.red)
//                                .padding()
                                .frame(width:280, height: 60)
                            
                        } else {
                            Text("Audio Engine Not Available")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }

                    QLFAUST_UI.PreviewDSP(jsonString: jsonString)
                }
                .padding()
            }
            .tabItem {
                Text("DSP")
            }
        }
    }
}

//struct QLFAUSTView: View {
//    let fileURL: URL
//
//    @State private var selectedTab = 0
//
//    var body: some View { render }
//
//    var faustString: String
//    var jsonString: String
//    var svgString: String?
//    var error: String
//
//    private var faustDspObject: FaustDSPObject?
//    
//    @State
//    private var audioEngine: AudioEngine?
//
//    public init(fileURL: URL, selectedTab: Int = 0) {
//        self.fileURL = fileURL
//        self.selectedTab = selectedTab
//
//        let file = fileURL.absoluteString.replacingOccurrences(of: "file://", with: "")
//
//        var errorString: NSString?
//
//        if let result = FaustDSPObject(path: file, error: &errorString) {
//            jsonString = result.getUIJSON()
//            svgString = result.getSVG()
//            faustDspObject = result
//            error = ""
//            
//            audioEngine = AudioEngine(faustDspObject!)
//            
//        } else {
//            jsonString = "[]"
//            faustString = ""
//            svgString = ""
//
//            faustDspObject = nil
//            audioEngine = nil
//
//            error = errorString! as String
//        }
//
//        do {
//            faustString = try String(contentsOf: fileURL, encoding: .utf8)
//        } catch {
//            faustString = ""
//        }
//    }
//
//    @ViewBuilder
//    private var render: some View {
//        TabView(selection: $selectedTab) {
//            QLFAUST_UI.PreviewFaustSource(faustString: faustString)
//                .tabItem {
//                    Text("Source")
//                }
//
//            QLFAUST_UI.PreviewSVG(svgString: svgString!)
//                .tabItem {
//                    Text("SVG")
//                }
//
//            VStack {
//                VStack(spacing: 20) {
//                    if let engine = audioEngine {
//                        Button(action: {
//                            engine.isRunning ? engine.stop() : engine.start()
//                        }) {
//                            Text(engine.isRunning ? "Stop Audio" : "Start Audio")
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .background(engine.isRunning ? Color.red : Color.green)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                                .animation(.easeInOut(duration: 0.2), value: engine.isRunning)
//                        }
//                        
//                        Text(engine.statusMessage)
//                            .foregroundColor(.red)
//                            .padding()
//                        
//                    }
//                    else { Text("Audio Engine Not Available") }
//
//                    QLFAUST_UI.PreviewDSP(jsonString: jsonString)
//                }
//                .padding()
//            }
//            .tabItem {
//                Text("DSP")
//            }
//        }
//    }
//}
