// Polls mic device status. Kills afplay when mic is in use by another app.
// No audio level detection — only checks if the input device is running.

import CoreAudio
import Foundation

func defaultInputDevice() -> AudioDeviceID? {
    var deviceID = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    let status = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID
    )
    return status == noErr ? deviceID : nil
}

func isMicDeviceRunning() -> Bool {
    guard let deviceID = defaultInputDevice() else { return false }
    var running: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &running)
    return status == noErr && running != 0
}

func isAfplayRunning() -> Bool {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    task.arguments = ["-x", "afplay"]
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    try? task.run()
    task.waitUntilExit()
    return task.terminationStatus == 0
}

// Poll every 300ms
while isAfplayRunning() {
    if isMicDeviceRunning() {
        // Mic is in use — stop TTS
        let kill = Process()
        kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        kill.arguments = ["afplay"]
        try? kill.run()
        kill.waitUntilExit()
        // Also kill the playback loop
        if let pidStr = try? String(contentsOfFile: "/tmp/tts-loop.pid", encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           let pid = Int32(pidStr) {
            Foundation.kill(pid, SIGTERM)
        }
        break
    }
    Thread.sleep(forTimeInterval: 0.3)
}
