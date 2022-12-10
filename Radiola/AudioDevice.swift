//
//  AudioDevice.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 10.12.2022.
//
//  The code of this file is based on Nathan's Perkins project SongDetector
//  https://github.com/gardner-lab/syllable-detector-swift
//

import AudioToolbox
import Foundation

class AudioSytstem {
    init() {
        // ==================================
        let onAudioObject = AudioObjectID(bitPattern: kAudioObjectSystemObject)

        var _propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster)

        AudioObjectAddPropertyListenerBlock(onAudioObject, &_propertyAddress, nil, dispatchEvent)
    }

    private func dispatchEvent(_ numAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        print(#function)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.AudioDeviceChanged, object: nil)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    static func devices() -> [AudioDevice] {
        // property address
        var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var size: UInt32 = 0

        // get input size
        if AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &size) != noErr {
            return []
        }

        // number of devices
        let deviceCount = Int(size) / MemoryLayout<AudioDeviceID>.size
        var audioDevices = [AudioDeviceID](repeating: AudioDeviceID(0), count: deviceCount)

        // get device ids
        if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &size, &audioDevices[0]) != noErr {
            return []
        }

        return audioDevices.compactMap {
            return AudioDevice(deviceID: $0)
        }
    }
}

struct AudioDevice {
    let deviceID: AudioDeviceID
    let UID: String
    let name: String
    let manufacturer: String
    let streamsInput: Int
    let streamsOutput: Int
    let sampleRateInput: Float64
    let sampleRateOutput: Float64
    let buffersInput: [AudioBuffer]
    let buffersOutput: [AudioBuffer]

    /* ****************************************
     *
     * ****************************************/
    init?(deviceID: AudioDeviceID) {
        self.deviceID = deviceID

        // property address
        var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceUID, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)

        var size: UInt32 = UInt32(MemoryLayout<CFString>.size)

        // get device UID
        var deviceUID = "" as CFString
        propertyAddress.mSelector = kAudioDevicePropertyDeviceUID
        if AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &deviceUID) != noErr {
            return nil
        }
        UID = String(deviceUID)

        // get deivce name
        var deviceName = "" as CFString
        propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString
        if AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &deviceName) != noErr {
            return nil
        }
        name = String(deviceName)

        // get deivce manufacturer
        var deviceManufacturer = "" as CFString
        propertyAddress.mSelector = kAudioDevicePropertyDeviceManufacturerCFString
        if AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &deviceManufacturer) != noErr {
            return nil
        }
        manufacturer = String(deviceManufacturer)

        // get number of streams
        // LAST AS IT CHANGES THE SCOPE OF THE PROPERTY ADDRESS
        propertyAddress.mSelector = kAudioDevicePropertyStreams
        propertyAddress.mScope = kAudioDevicePropertyScopeInput
        if AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &size) != noErr {
            return nil
        }
        streamsInput = Int(size) / MemoryLayout<AudioStreamID>.size

        if 0 < streamsInput {
            // get sample rate
            size = UInt32(MemoryLayout<Float64>.size)
            var sampleRateInput: Float64 = 0.0
            propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate
            if AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &sampleRateInput) != noErr {
                return nil
            }
            self.sampleRateInput = sampleRateInput

            // get stream configuration
            size = 0
            propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration
            if AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &size) != noErr {
                return nil
            }

            // allocate
            // is it okay to assume binding? or should bind (but if so, what capacity)?
            let bufferList = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment).assumingMemoryBound(to: AudioBufferList.self)
            let ok = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, bufferList)
            defer {
                free(bufferList)
            }
            guard ok == noErr else { return nil }

            // turn into something swift usable
            let usableBufferList = UnsafeMutableAudioBufferListPointer(bufferList)

            // add device buffers
            var buffersInput = [AudioBuffer]()
            for ab in usableBufferList {
                buffersInput.append(ab)
            }
            self.buffersInput = buffersInput
        } else {
            buffersInput = []
            sampleRateInput = 0.0
        }

        propertyAddress.mSelector = kAudioDevicePropertyStreams
        propertyAddress.mScope = kAudioDevicePropertyScopeOutput
        if AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &size) != noErr {
            return nil
        }
        streamsOutput = Int(size) / MemoryLayout<AudioStreamID>.size

        if 0 < streamsOutput {
            // get sample rate
            size = UInt32(MemoryLayout<Float64>.size)
            var sampleRateOutput: Float64 = 0.0
            propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate
            if AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &sampleRateOutput) != noErr {
                return nil
            }
            self.sampleRateOutput = sampleRateOutput

            // get stream configuration
            size = 0
            propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration
            if AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &size) != noErr {
                return nil
            }

            // allocate
            // is it okay to assume binding? or should bind (but if so, what capacity)?
            let bufferList = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment).assumingMemoryBound(to: AudioBufferList.self)
            let ok = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, bufferList)
            defer {
                free(bufferList)
            }
            guard ok == noErr else { return nil }

            // turn into something swift usable
            let usableBufferList = UnsafeMutableAudioBufferListPointer(bufferList)

            // add device buffers
            var buffersOutput = [AudioBuffer]()
            for ab in usableBufferList {
                buffersOutput.append(ab)
            }
            self.buffersOutput = buffersOutput
        } else {
            buffersOutput = []
            sampleRateOutput = 0.0
        }
    }
}
