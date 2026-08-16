import SwiftUI

#if os(iOS)
public struct WorkspaceView: View {
    private let fileSystem: VirtualFileSystem
    private let proposalSink: EditProposalSink

    @State private var files: [String: String]
    @State private var selectedPath = "Sources/App.swift"
    @State private var editorText = ""
    @State private var prompt = ""
    @State private var apiKey = ""
    @State private var status = "Ready"
    @State private var isRunning = false
    @State private var pendingProposal: EditFileProposal?

    public init() {
        let initial: [String: String] = [
            "Sources/App.swift": "import SwiftUI\n\n@main\nstruct App: App {\n    var body: some Scene {\n        WindowGroup { ContentView() }\n    }\n}\n",
            "Sources/ContentView.swift": "import SwiftUI\n\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Hello, Amethyst\")\n    }\n}\n"
        ]
        let fs = VirtualFileSystem(initialFiles: initial)
        self.fileSystem = fs
        self.proposalSink = EditProposalSink()
        _files = State(initialValue: initial)
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedPath) {
                Section("EXPLORER") {
                    ForEach(files.keys.sorted(), id: \.self) { path in
                        Label(path, systemImage: path.hasSuffix(".swift") ? "swift" : "doc")
                            .tag(path)
                    }
                }
            }
            .navigationTitle("Amethyst")
            .onChange(of: selectedPath) { _, path in
                editorText = files[path] ?? ""
            }
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    Text(selectedPath).font(.caption.monospaced()).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "sparkles")
                    Text("Agent").font(.caption.bold())
                    Circle().fill(isRunning ? .orange : .green).frame(width: 7, height: 7)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.thinMaterial)

                MonacoEditor(text: $editorText)
                    .onChange(of: editorText) { _, value in
                        files[selectedPath] = value
                        Task { try? await fileSystem.replaceFile(path: selectedPath, content: value) }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                VStack(spacing: 8) {
                    HStack {
                        Text("AI Agent").font(.headline)
                        Spacer()
                        Text(status).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    HStack {
                        SecureField("OpenAI API key (kept in memory for this session)", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Ask the agent to create or edit code…", text: $prompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button { sendPrompt() } label: {
                            Image(systemName: isRunning ? "hourglass" : "arrow.up.circle.fill").font(.title2)
                        }
                        .disabled(isRunning || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || apiKey.isEmpty)
                    }
                }
                .padding(12)
                .background(.regularMaterial)
                .frame(minHeight: 125, maxHeight: 190)
            }
            .overlay {
                if let proposal = pendingProposal {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    DiffView(proposal: proposal, onAccept: { accept(proposal) }, onReject: { reject(proposal) })
                }
            }
        }
        .task { await refreshFiles(); editorText = files[selectedPath] ?? "" }
    }

    private func sendPrompt() {
        let userPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        prompt = ""
        isRunning = true
        status = "Agent working…"

        Task {
            do {
                let registry = ToolRegistry(tools: [
                    CreateFileTool(fileSystem: fileSystem),
                    ReadFileTool(fileSystem: fileSystem),
                    EditFileTool(fileSystem: fileSystem, proposalSink: proposalSink)
                ])
                let provider = OpenAIResponsesProvider(apiKey: apiKey)
                let agent = try await MainActor.run { AgentLoop(provider: provider, registry: registry) }
                let response = try await agent.run(userPrompt: userPrompt)
                if let calls = response.message.toolCalls {
                    status = "Completed \(calls.count) tool call(s)"
                } else {
                    status = response.message.content ?? "Done"
                }
                await refreshFiles()
                if let id = await proposalSink.proposalIDs().first {
                    pendingProposal = await proposalSink.proposal(id: id)
                }
            } catch {
                status = error.localizedDescription
            }
            isRunning = false
        }
    }

    private func refreshFiles() async {
        let paths = await fileSystem.allFiles()
        var snapshot: [String: String] = [:]
        for path in paths { snapshot[path] = try? await fileSystem.readFile(path: path) }
        await MainActor.run {
            files = snapshot
            editorText = files[selectedPath] ?? ""
        }
    }

    private func accept(_ proposal: EditFileProposal) {
        Task {
            do {
                try await proposalSink.accept(id: proposal.id, in: fileSystem)
                pendingProposal = nil
                await refreshFiles()
                status = "Change accepted"
            } catch { status = error.localizedDescription }
        }
    }

    private func reject(_ proposal: EditFileProposal) {
        Task {
            await proposalSink.reject(id: proposal.id)
            pendingProposal = nil
            status = "Change rejected"
        }
    }
}
#endif
