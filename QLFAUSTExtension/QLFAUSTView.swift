//  Created by alex on 16/03/2025.

import Cocoa
import Quartz
import SwiftUI

import QLFAUST_UI
import UniformTypeIdentifiers

import FaustSwiftUI

// MARK: -

class FaustUIProxy: FaustUIValueBinding {
    var faustDspObject: FaustDSPObject?

    public func getValue(for address: String, default defaultValue: Double) -> Double {
        if let dsp = faustDspObject {
            return Double(dsp.getParameter(address))
        }
        return defaultValue
    }

    public func setValue(_ value: Double, for address: String) {
        if let dsp = faustDspObject {
            dsp.setParameter(address, value: Float(value))
        }
    }
}

// MARK: -

struct QLFAUSTView: View {
    let fileURL: URL

    @State private var selectedTab = 0

    @State private var faustString = ""
    @State private var jsonString = "[]"
    @State private var svgString: String? = nil
    @State private var error = ""

    @State private var faustDspObject: FaustDSPObject?
    private var uiProxy: FaustUIProxy

    @StateObject private var audioEngine: AudioEngine

    public init(fileURL: URL, selectedTab: Int = 0) {
        self.fileURL = fileURL
        self.selectedTab = selectedTab

        uiProxy = FaustUIProxy()

        let file = fileURL.absoluteString.replacingOccurrences(of: "file://", with: "")

        var errorString: NSString?

        if let result = FaustDSPObject(path: file, error: &errorString) {
            _jsonString = State(initialValue: result.getUIJSON())
            _svgString = State(initialValue: result.getSVG())
            _faustDspObject = State(initialValue: result)
            _error = State(initialValue: "")
            _audioEngine = StateObject(wrappedValue: AudioEngine())

            uiProxy.faustDspObject = faustDspObject

        } else {
            _jsonString = State(initialValue: "[]")
            _faustString = State(initialValue: "")
            _svgString = State(initialValue: nil)
            _faustDspObject = State(initialValue: nil)
            _audioEngine = StateObject(wrappedValue: AudioEngine())
            _error = State(initialValue: errorString! as String)
        }

        do {
            _faustString = State(initialValue: try String(contentsOf: fileURL, encoding: .utf8))
        } catch {
            _faustString = State(initialValue: "")
        }
    }

    @State private var displayCode = true
    @State private var displaySVG = true
    @State private var displayDSP = true

    public var body: some View { render }

    @ViewBuilder
    private var render: some View {
        // toolbar:
        HStack {
            Button(action: {
                displayCode.toggle()
            }) {
                Image(systemName: "doc.plaintext")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding()
                    .foregroundColor(displayCode ? .blue : .gray)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                displaySVG.toggle()
            }) {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding()
                    .foregroundColor(displaySVG ? .blue : .gray)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                displayDSP.toggle()
            }) {
                Image(systemName: "hifispeaker")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding()
                    .foregroundColor(displayDSP ? .blue : .gray)
            }
            .buttonStyle(.plain)
            
            HStack {
                if audioEngine.available {
                    let engine = audioEngine

                    Button(action: {
                        engine.isRunning ? engine.stop() : engine.start()
                    }) {
//                        Text(engine.isRunning ? "Stop Audio" : "Start Audio")
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 30)
//                            .background(engine.isRunning ? Color.red : Color.green)
//                            .foregroundColor(.white)
//                            .animation(.easeInOut(duration: 0.2), value: engine.isRunning)
                        
                        Image(systemName: engine.isRunning ? "stop.circle.fill" : "play.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding()
                            .foregroundColor(engine.isRunning ? .gray : .blue)
                    }
                    .frame(width: 120, height: 30)
                    .buttonStyle(.plain)
                    
                    Text(engine.statusMessage)
                    
                    Text("Inputs: \(_faustDspObject.wrappedValue!.getInputsCount())").frame(maxWidth:80)
                    Text("Outputs: \(_faustDspObject.wrappedValue!.getOutputsCount())").frame(maxWidth:80)
                    

                } else {
                    Text(audioEngine.statusMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .frame(height: 32)
            .cornerRadius(5)
        }
        .padding()
        .frame(height: 32)
        .cornerRadius(5)

        HStack {
            if displayCode || (!displaySVG && !displayDSP) {
                QLFAUST_UI.PreviewFaustSource(faustString: faustString)
            }

            VStack {
                if displaySVG {
                    if let svgString = svgString {
                        QLFAUST_UI.PreviewSVG(svgString: svgString)

                    } else {
                        Text("No SVG available")
                    }
                }

                // from here
                if displayDSP {
                    VStack {
                        ScrollView {
                            QLFAUST_UI.PreviewDSP(jsonString: jsonString, viewModel: uiProxy)
                                .onAppear {
                                    if let object = faustDspObject {
                                        _audioEngine.wrappedValue.setup(object)
                                    }
                                }
                                .padding()
                        }
                    }
                }
            }
        }
    }
}
