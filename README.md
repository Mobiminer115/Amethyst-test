# Amethyst Test — iPad AI IDE

Experimental iPad-first IDE architecture for Amethyst, written in Swift/SwiftUI.

## Current architecture

- SwiftUI iPad workspace with Explorer + editor + bottom AI panel
- `WKWebView` Monaco editor bridge
- Actor-based Virtual File System
- OpenAI Responses API provider with function calling
- Agent tools: `create_file`, `read_file`, `edit_file`
- `edit_file` creates a proposal and never overwrites without approval
- Diff overlay with Accept / Reject
- Swift Package tests and GitHub Actions CI

## OpenAI setup

Do not hard-code an API key in source control. Pass it from Keychain or another secure app configuration layer. The provider is compatible with the OpenAI Responses API endpoint and is intentionally isolated so an OpenAI-compatible endpoint can be substituted later.

The current provider sends custom function tools and parses `function_call` output items, then the Agent Tool Executor executes the selected local tool. OpenAI's Responses API documents custom function tools and `function_call_output` as the tool loop mechanism.

## Open the project on a Mac

1. Clone the repository.
2. Open the folder in Xcode.
3. Use the Swift Package manifest to inspect/build the core module.
4. For an installable iPad app target, create an iOS App target named `AmethystIDE` and add the `AmethystIDE` source directory to that target. Set the deployment target to iOS 17 or newer.
5. Select an iPad simulator or a connected iPad and Run.

## Monaco

The current `MonacoEditor` is a WKWebView bridge and loads Monaco 0.52.2 from jsDelivr. For a production/offline build, vendor the Monaco distribution under app resources and change the HTML loader paths to the bundled files.

## CI

GitHub Actions runs `swift build` and `swift test` on a macOS runner for every push to `main` and pull request targeting `main`.

## Roadmap

1. Persist VFS projects in Application Support.
2. Connect the AI panel to `OpenAIResponsesProvider` and the Agent loop.
3. Add real tree/folder models and multi-tab editing.
4. Replace the simple diff preview with a line-based Monaco diff editor.
5. Vendor Monaco for offline use.
6. Add Keychain-backed API configuration.
7. Add undo/redo transactions and agent permissions.
8. Add Xcode project generation and simulator build/run integration.
