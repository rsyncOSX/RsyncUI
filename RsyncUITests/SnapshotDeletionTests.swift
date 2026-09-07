import Foundation
@testable import RsyncUI
import Testing

struct SnapshotDeletionTests {
    @Test(arguments: ["", "./", "./.", "./..", "./../7", "./0", "./7/other", "./7;echo bad"])
    func rejectsInvalidSnapshot(_ catalog: String) {
        #expect(throws: SnapshotDeletionError.self) {
            try SnapshotDeletionPath.target(root: "/backup/", catalog: catalog)
        }
    }

    @Test(arguments: ["", "/", "//", "/./", "..", "/backup/../", "/backup/\n"])
    func rejectsInvalidRoot(_ root: String) {
        #expect(throws: SnapshotDeletionError.self) {
            try SnapshotDeletionPath.target(root: root, catalog: "./7")
        }
    }

    @Test("Shell quoting preserves spaces, quotes and metacharacters as one argument")
    func shellRoundTrip() throws {
        let target = try SnapshotDeletionPath.target(root: "/backup/My Disk's $(unused);/", catalog: "./7")
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "printf '%s' " + SnapshotDeletionPath.shellQuote(target)]
        process.standardOutput = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        #expect(String(data: data, encoding: .utf8) == target)
    }
}
