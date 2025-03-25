//
//  AudioEngine.swift
//  QLFAUST
//
//  Created by alex on 25/03/2025.
//


import AVFoundation
import AudioToolbox

class AudioEngine: ObservableObject {
    private var audioUnit: AudioUnit?
    
    @Published var isRunning = false  // Observable in SwiftUI
    @Published var statusMessage: String  // Error messages
    
    private var faustDSP: FaustDSPObject

    init(_ object:FaustDSPObject) {
        self.faustDSP = object
        self.statusMessage = "Ready"
    }

    func start() {
        guard !isRunning else { return }

        var desc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_DefaultOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        guard let component = AudioComponentFindNext(nil, &desc) else {
            statusMessage = "⚠️ Failed to find audio component"
            return
        }
        
        let status = AudioComponentInstanceNew(component, &audioUnit)
        guard status == noErr, let unit = audioUnit else {
            statusMessage = "⚠️ Failed to create audio unit"
            return
        }

        let sampleRate: Double = 44100.0
        var streamFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 4,
            mFramesPerPacket: 1,
            mBytesPerFrame: 4,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 32,
            mReserved: 0
        )

        let formatStatus = AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, UInt32(MemoryLayout.size(ofValue: streamFormat)))
        if formatStatus != noErr {
            statusMessage = "⚠️ Failed to set audio format"
            return
        }

        var callbackStruct = AURenderCallbackStruct(
            inputProc: audioRenderCallback,
            inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        let callbackStatus = AudioUnitSetProperty(unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, UInt32(MemoryLayout.size(ofValue: callbackStruct)))
        if callbackStatus != noErr {
            statusMessage = "⚠️ Failed to set audio callback"
            return
        }

        let initStatus = AudioUnitInitialize(unit)
        if initStatus != noErr {
            statusMessage = "⚠️ Failed to initialize AudioUnit"
            return
        }

        let startStatus = AudioOutputUnitStart(unit)
        if startStatus != noErr {
            statusMessage = "⚠️ Failed to start AudioUnit"
            return
        }

        isRunning = true
        statusMessage = "🔊 AudioEngine started"
    }

    func stop() {
        guard isRunning else { return }

        if let unit = audioUnit {
            let stopStatus = AudioOutputUnitStop(unit)
            let uninitStatus = AudioUnitUninitialize(unit)
            let disposeStatus = AudioComponentInstanceDispose(unit)

            if stopStatus != noErr {
                statusMessage = "⚠️ Failed to stop AudioUnit"
            }
            if uninitStatus != noErr {
                statusMessage = "⚠️ Failed to uninitialize AudioUnit"
            }
            if disposeStatus != noErr {
                statusMessage = "⚠️ Failed to dispose AudioUnit"
            }

            audioUnit = nil
        }
        isRunning = false
        statusMessage = "🔇 AudioEngine stopped"
    }
    
    deinit {
        stop();
    }

    private let audioRenderCallback: AURenderCallback = { (
        inRefCon, _, _, _, inNumberFrames, ioData
    ) -> OSStatus in
        guard let ioData = ioData,
              let buffers = ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self) else {
            return noErr
        }

        let engine = Unmanaged<AudioEngine>.fromOpaque(inRefCon).takeUnretainedValue()
        engine.faustDSP.processAudio(buffers, output: buffers, frames: Int32(inNumberFrames))

        return noErr
    }
}
