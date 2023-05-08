import ArgumentParser
import Hummingbird

@main
struct App: AsyncParsableCommand, AppArguments {
    
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    func run() async throws {
        let app = HBApplication(
            configuration: .init(
                address: .hostname(self.hostname, port: self.port),
                serverName: "TodosExample"
            )
        )
        try await app.configure(self)
        try app.start()
        app.wait()
    }
}
