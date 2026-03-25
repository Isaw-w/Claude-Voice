// Monitors mic input and kills 'say' when speech is detected.
// Runs in background alongside TTS, exits when 'say' is no longer running.

import AVFoundation
import Foundation

let engine = AVAudioEngine()
let inputNode = engine.inputNode
let format = inputNode.outputFormat(forBus: 0)
let threshold: Float = 0.02  // adjust if too sensitive or not enough

inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
    let channelData = buffer.floatChannelData?[0]
    let frames = buffer.frameLength
    var sum: Float = 0
    for i in 0..<Int(frames) {
        sum += abs(channelData![i])
    }
    let avg = sum / Float(frames)
    if avg > threshold {
        // User is speaking — kill both osascript (parent) and say (child)
        for proc in ["osascript", "say"] {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            task.arguments = [proc]
            try? task.run()
            task.waitUntilExit()
        }
        exit(0)
    }
}

do {
    try engine.start()
} catch {
    exit(1)
}

// Check every second if 'say' is still running; exit if not
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    let check = Process()
    check.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    check.arguments = ["-x", "say"]
    check.standardOutput = FileHandle.nullDevice
    check.standardError = FileHandle.nullDevice
    try? check.run()
    check.waitUntilExit()
    if check.terminationStatus != 0 {
        // 'say' has finished, no need to monitor
        exit(0)
    }
}

RunLoop.main.run()
