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

    /* ****************************************
     *
     * ****************************************/
    static func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = kAudioObjectUnknown
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &size, &deviceID)

        guard status == noErr else {
            warning("Error receiving the default device: \(status)")
            return nil
        }

        return deviceID
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
        var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceUID, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)

        var size: UInt32 = UInt32(MemoryLayout<CFString>.size)

        // get device UID
        var deviceUID: CFString = "" as CFString
        propertyAddress.mSelector = kAudioDevicePropertyDeviceUID
        let statusUID = withUnsafeMutablePointer(to: &deviceUID) { pointer in
            AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, pointer)
        }
        guard statusUID == noErr else { return nil }
        UID = deviceUID as String

        // get device name
        var deviceName: CFString = "" as CFString
        propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString
        let statusName = withUnsafeMutablePointer(to: &deviceName) { pointer in
            AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, pointer)
        }
        guard statusName == noErr else { return nil }
        name = deviceName as String

        // get device manufacturer
        var deviceManufacturer: CFString = "" as CFString
        propertyAddress.mSelector = kAudioDevicePropertyDeviceManufacturerCFString
        let statusManufacturer = withUnsafeMutablePointer(to: &deviceManufacturer) { pointer in
            AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, pointer)
        }
        guard statusManufacturer == noErr else { return nil }
        manufacturer = deviceManufacturer as String

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

            // allocate memory for buffer list
            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
            defer {
                bufferList.deallocate()
            }
            guard AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, bufferList) == noErr else {
                return nil
            }

            // convert to Swift usable buffer list
            let usableBufferList = UnsafeMutableAudioBufferListPointer(bufferList)
            buffersInput = Array(usableBufferList)
        } else {
            buffersInput = []
            sampleRateInput = 0.0
        }

        // get number of output streams
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

            // allocate memory for buffer list
            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
            defer {
                bufferList.deallocate()
            }
            guard AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, bufferList) == noErr else {
                return nil
            }

            // convert to Swift usable buffer list
            let usableBufferList = UnsafeMutableAudioBufferListPointer(bufferList)
            buffersOutput = Array(usableBufferList)
        } else {
            buffersOutput = []
            sampleRateOutput = 0.0
        }
    }
}
