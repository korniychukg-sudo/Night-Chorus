import Foundation

let args = CommandLine.arguments
let outDir = args.count > 1 ? args[1] : "./out"
let mode = args.count > 2 ? args[2] : "all"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

if mode == "icon" || mode == "all" {
    buildIcon(dir: outDir)
    print("icon")
}
if mode == "plates" || mode == "all" {
    var jobs: [() -> Void] = []
    for art in voiceArt { jobs.append { voicePlate(art, dir: outDir) } }
    for job in sceneJobs(dir: outDir) { jobs.append(job) }
    let lock = NSLock()
    var done = 0
    DispatchQueue.concurrentPerform(iterations: jobs.count) { index in
        jobs[index]()
        lock.lock()
        done += 1
        if done % 10 == 0 { print("plates \(done)/\(jobs.count)") }
        lock.unlock()
    }
    print("plates \(jobs.count)")
}
print("done")
