import XCTest
@testable import AmethystIDECore

final class VirtualFileSystemTests: XCTestCase {
    func testCreateAndReadFile() async throws {
        let fs = VirtualFileSystem()
        try await fs.createFile(path: "Views/LoginView.swift", content: "struct LoginView {}")
        XCTAssertEqual(try await fs.readFile(path: "Views/LoginView.swift"), "struct LoginView {}")
    }

    func testEditProposalDoesNotMutateUntilAccepted() async throws {
        let fs = VirtualFileSystem(initialFiles: ["A.swift": "let value = 1"])
        let sink = EditProposalSink()
        let tool = EditFileTool(fileSystem: fs, proposalSink: sink)

        _ = try await tool.execute(arguments: [
            "path": .string("A.swift"),
            "old_text": .string("1"),
            "new_text": .string("2")
        ])

        XCTAssertEqual(try await fs.readFile(path: "A.swift"), "let value = 1")
    }
}
