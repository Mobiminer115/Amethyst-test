import SwiftUI
import WebKit

#if os(iOS)
public struct MonacoEditor: UIViewRepresentable {
    @Binding public var text: String
    public let language: String

    public init(text: Binding<String>, language: String = "swift") {
        _text = text
        self.language = language
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "editorChanged")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.loadHTMLString(Self.html, baseURL: nil)
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        guard !context.coordinator.isEditing else { return }
        let payload = (try? JSONEncoder().encode(text)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        let languagePayload = (try? JSONEncoder().encode(language)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"plaintext\""
        webView.evaluateJavaScript("window.setEditorContent(\(payload), \(languagePayload));")
    }

    public final class Coordinator: NSObject, WKScriptMessageHandler {
        private var parent: MonacoEditor
        fileprivate var isEditing = false

        init(_ parent: MonacoEditor) { self.parent = parent }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "editorChanged", let value = message.body as? String else { return }
            isEditing = true
            parent.text = value
            DispatchQueue.main.async { [weak self] in self?.isEditing = false }
        }
    }

    private static let html = """
    <!doctype html>
    <html><head><meta name='viewport' content='width=device-width,initial-scale=1'>
    <style>html,body,#container{width:100%;height:100%;margin:0;overflow:hidden;background:#1e1e1e}</style>
    <script src='https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs/loader.js'></script>
    </head><body><div id='container'></div>
    <script>
    let editor;
    require.config({ paths: { vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs' } });
    require(['vs/editor/editor.main'], function() {
      editor = monaco.editor.create(document.getElementById('container'), {
        value: '', language: 'swift', theme: 'vs-dark', automaticLayout: true,
        minimap: { enabled: false }, fontSize: 14, smoothScrolling: true,
        padding: { top: 12 }
      });
      editor.onDidChangeModelContent(function() {
        window.webkit.messageHandlers.editorChanged.postMessage(editor.getValue());
      });
    });
    window.setEditorContent = function(value, language) {
      if (!editor) return;
      if (editor.getValue() !== value) editor.setValue(value);
      monaco.editor.setModelLanguage(editor.getModel(), language);
    };
    </script></body></html>
    """
}
#endif
