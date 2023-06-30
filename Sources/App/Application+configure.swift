import Hummingbird
import HummingbirdFoundation
import HummingbirdPostgresDatabase
import HummingbirdSQLiteDatabase

public protocol AppArguments {}

extension HBApplication {
    
    func configure(_ args: AppArguments) async throws {
//        services.setUpPostgresDatabase(
//            configuration: .init(
//                host: "localhost",
//                port: 5432,
//                username: "hummingbird",
//                password: "hummingbird",
//                database: "hb-password",
//                tls: .disable
//            ),
//            eventLoopGroup: eventLoopGroup,
//            logger: logger
//        )
        
        services.setUpSQLiteDatabase(
            storage: .file(path: "./hb-todos.sqlite"),
            threadPool: threadPool,
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )

        try await db.execute(
            .init(unsafeSQL:
                """
                CREATE TABLE IF NOT EXISTS todos (
                    "id" uuid PRIMARY KEY,
                    "title" text NOT NULL,
                    "order" integer,
                    "completed" boolean,
                    "url" text
                );
                """
            )
        )

        // set encoder and decoder
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        // logger
        logger.logLevel = .debug
        // middleware
        middleware.add(HBLogRequestsMiddleware(.debug))
        middleware.add(HBCORSMiddleware(
            allowOrigin: .originBased,
            allowHeaders: ["Content-Type"],
            allowMethods: [.GET, .OPTIONS, .POST, .DELETE, .PATCH]
        ))

        router.get("/") { _ in
            "Hello"
        }
        
        TodoController().addRoutes(to: router.group("todos"))
    }
}
