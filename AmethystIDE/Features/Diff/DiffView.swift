import SwiftUI

#if os(iOS)
public struct DiffView: View {
    public let proposal: EditFileProposal
    public let onAccept: () -> Void
    public let onReject: () -> Void

    public init(proposal: EditFileProposal, onAccept: @escaping () -> Void, onReject: @escaping () -> Void) {
        self.proposal = proposal
        self.onAccept = onAccept
        self.onReject = onReject
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("AI Change Preview").font(.headline)
                    Text(proposal.path).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reject", role: .cancel, action: onReject)
                Button("Accept", action: onAccept).buttonStyle(.borderedProminent)
            }

            ScrollView([.vertical, .horizontal]) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(proposal.oldText.split(separator: "\\n", omittingEmptySubsequences: false), id: \.self) { line in
                        Text("- \(line)").font(.system(.caption, design: .monospaced)).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 8)
                    }
                    ForEach(proposal.newText.split(separator: "\\n", omittingEmptySubsequences: false), id: \.self) { line in
                        Text("+ \(line)").font(.system(.caption, design: .monospaced)).foregroundStyle(.green).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 8)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
        .padding()
    }
}
#endif
