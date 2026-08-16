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

        let result = try await tool.execute(arguments: [
            "path": .string("A.swift"),
            "old_text": .string("1"),
            "new_text": .string("2")
        ])

        XCTAssertTrue(result.success)
        XCTAssertEqual(try await fs.readFile(path: "A.swift"), "let value = 1")
    }

    func testAcceptProposalMutatesFile() async throws {
        let fs = VirtualFileSystem(initialFiles: ["A.swift": "let value = 1"])
        let sink = EditProposalSink()
        let tool = EditFileTool(fileSystem: fs, proposalSink: sink)

        _ = try await tool.execute(arguments: [
            "path": .string("A.swift"),
            "old_text": .string("1"),
            "new_text": .string("2")
        ])

        let proposal = await sink.proposal(id: (await sink.proposalIDs()).first!)
        XCTAssertNotNil(proposal)
        if let proposal { try await sink.accept(id: proposal.id, in: fs) }
        XCTAssertEqual(try await fs.readFile(path: "A.swift"), "let value = 2")
    }

    func testToolRegistryContainsExpectedToolSchemas() throws {
        let fs = VirtualFileSystem()
        let sink = EditProposalSink()
        let registry = ToolRegistry(tools: [
            CreateFileTool(fileSystem: fs),
            ReadFileTool(fileSystem: fs),
            EditFileTool(fileSystem: fs, proposalSink: sink)
        ])

        XCTAssertEqual(Set(registry.allTools().map(\.name)), ["create_file", "read_file", "edit_file"])
        XCTAssertEqual(registry.openAICompatibleSchemas().count, 3)
    }
}
