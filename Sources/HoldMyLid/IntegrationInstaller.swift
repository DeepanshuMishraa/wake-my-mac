import Foundation

enum IntegrationInstaller {
    static func install() {
        installResource(
            name: "hold-my-lid-pi",
            extension: "ts",
            destination: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".pi/agent/extensions/hold-my-lid.ts")
        )
        installResource(
            name: "hold-my-lid-opencode",
            extension: "js",
            destination: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".config/opencode/plugins/hold-my-lid.js")
        )
        let antigravityRoot = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".gemini/config/plugins/hold-my-lid-antigravity", isDirectory: true)
        installResource(name: "antigravity-plugin", extension: "json", destination: antigravityRoot.appendingPathComponent("plugin.json"))
        installResource(name: "antigravity-hooks", extension: "json", destination: antigravityRoot.appendingPathComponent("hooks.json"))
        installResource(name: "hold-my-lid-antigravity", extension: "py", destination: antigravityRoot.appendingPathComponent("hold-my-lid-antigravity.py"))
    }

    private static func installResource(name: String, extension ext: String, destination: URL) {
        guard let source = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Integrations"),
              let data = try? Data(contentsOf: source) else { return }
        if (try? Data(contentsOf: destination)) == data { return }
        do {
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: destination, options: .atomic)
        } catch {
            // The UI falls back to process presence if an integration cannot be installed.
        }
    }
}
