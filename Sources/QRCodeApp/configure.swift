import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // ✅ Abilita le sessioni
    app.middleware.use(app.sessions.middleware)
    
    // 🔹 Imposta la porta automaticamente se fornita da Render
    if let port = Environment.get("PORT").flatMap(Int.init) {
        app.http.server.configuration.port = port
    } else {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 8095 // fallback locale
    }

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateQRCode())
    app.migrations.add(CreateScan())


    app.views.use(.leaf)

    // register routes
    try routes(app)
}
