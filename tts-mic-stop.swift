// Monitors mic input and kills 'say' when user speech is detected.
// Requires several consecutive loud frames to avoid speaker bleed false triggers.

import AVFoundation
import Foundation

let engine = AVAudioEngine()
let inputNode = engine.inputNode
let format = inputNode.outputFormat(forBus: 0)
let threshold: Float = 0.05
let requiredFrames = 5  // need 5 consecutive frames above threshold
let gracePeriod: TimeInterval = 3.0
let startTime = Date()
var consecutiveCount = 0

inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
    guard Date().timeIntervalSince(startTime) > gracePeriod else { return }

    let channelData = buffer.floatChannelData?[0]
    let frames = buffer.frameLength
    var sum: Float = 0
    for i in 0..<Int(frames) {
        sum += abs(channelData![i])
    }
    let avg = sum / Float(frames)

    if avg > threshold {
        consecutiveCount += 1
    } else {
        consecutiveCount = 0
    }

    if consecutiveCount >= requiredFrames {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        task.arguments = ["say"]
        try? task.run()
        task.waitUntilExit()
        exit(0)
    }
}

do {
    try engine.start()
} catch {
    exit(1)
}

Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    let check = Process()
    check.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    check.arguments = ["-x", "say"]
    check.standardOutput = FileHandle.nullDevice
    check.standardError = FileHandle.nullDevice
    try? check.run()
    check.waitUntilExit()
    if check.terminationStatus != 0 {
        exit(0)
    }
}

RunLoop.main.run()
