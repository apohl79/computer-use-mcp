import Foundation

func argumentsWithoutLaunchServicesProcessNumber(_ arguments: [String]) -> [String] {
    arguments.filter { !$0.hasPrefix("-psn_") }
}

func shouldRunHostWithoutArguments(arguments: [String], bundleURL: URL) -> Bool {
    arguments.isEmpty && bundleURL.pathExtension == "app"
}

func runHost() async -> Never {
    guard Bundle.main.bundleURL.pathExtension == "app" else {
        FileHandle.standardError.write(
            Data("The persistent host must be launched from a .app bundle.\n".utf8)
        )
        exit(2)
    }

    while true {
        do {
            try await DaemonClient.shared.keepAlive()
        } catch {
            daemonLog("GUI host could not connect to the engine daemon: \(error)")
        }
        try? await Task.sleep(for: .seconds(30))
    }
}
