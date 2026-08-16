import SwiftUI

#if os(iOS)
public struct WorkspaceView: View {
    @State private var files: [String: String] = [
        "Sources/App.swift": "import SwiftUI\n\n@main\nstruct App: App {\n    var body: some Scene {\n        WindowGroup { ContentView() }\n    }\n}\n",
        "Sources/ContentView.swift": "import SwiftUI\n\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Hello, Amethyst\")\n    }\n}\n"
    ]
    @State private var selectedPath = "Sources/App.swift"
    @State private var editorText = ""
    @State private var prompt = ""

    public init() {}

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
            .onChange(of: selectedPath) { _, path in editorText = files[path] ?? "" }
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    Text(selectedPath).font(.caption.monospaced()).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "sparkles")
                    Text("Agent").font(.caption.bold())
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.thinMaterial)

                MonacoEditor(text: $editorText)
                    .onChange(of: editorText) { _, value in files[selectedPath] = value }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                VStack(spacing: 8) {
                    HStack {
                        Text("AI Agent").font(.headline)
                        Spacer()
                        Text("Tools enabled").font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(alignment: .bottom) {
                        TextField("Ask the agent to create or edit code…", text: $prompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button { prompt = "" } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }
                            .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(12)
                .background(.regularMaterial)
                .frame(minHeight: 120, maxHeight: 190)
            }
        }
        .task { editorText = files[selectedPath] ?? "" }
    }
}
#endif
