import Vapor
import Fluent
import FluentPostgresDriver
import Leaf
import NIOSSL

public func configure(_ app: Application) async throws {

    // ================================
    // DIRECTORY FIX
    // ================================
    app.directory.publicDirectory = app.directory.workingDirectory + "Public/"
    app.directory.viewsDirectory = app.directory.workingDirectory + "Resources/Views/"
    app.directory.resourcesDirectory = app.directory.workingDirectory + "Resources/"
    
    // ================================
    // MIDDLEWARE
    // ================================
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    // ================================
    // HTTP SERVER CONFIG
    // ================================
    app.http.server.configuration.hostname = "0.0.0.0"
    if let port = Environment.get("PORT").flatMap(Int.init) {
        app.http.server.configuration.port = port
    } else {
        app.http.server.configuration.port = 8095
    }
    
    
    print("SUPABASE_URL:", Environment.get("SUPABASE_URL") ?? "non impostato")
    print("SUPABASE_API_KEY:", Environment.get("SUPABASE_API_KEY") != nil ? "<ok>" : "non impostato")

    
    // QUESTA PARTE COMMENTATA SERVIVA CON FLUENT PER DISTINGURE DB LOCALE DA DB PRODUZIONE
    
//    // ================================
//        // DATABASE CONFIG
//        // ================================
//        let dbHost = Environment.get("DATABASE_HOST") ?? "localhost"
//        let dbPort = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432
//        let dbUser = Environment.get("DATABASE_USERNAME") ?? "vapor_username"
//        let dbPassword = Environment.get("DATABASE_PASSWORD") ?? "vapor_password"
//        let dbName = Environment.get("DATABASE_NAME") ?? "vapor_database"
    
        
        //let postgresConfig: SQLPostgresConfiguration
        
//        if app.environment == .production {
//            var nioTLS = TLSConfiguration.makeClientConfiguration()
//            // Render + Supabase: fondamentale disabilitare la verifica per i certificati self-signed
//            nioTLS.certificateVerification = .none
//            
//            let sslContext = try NIOSSLContext(configuration: nioTLS)
//            
//            // Lasciamo che Swift inferisca il tipo di 'tls:' direttamente qui
//            postgresConfig = SQLPostgresConfiguration(
//                hostname: dbHost,
//                port: dbPort,
//                username: dbUser,
//                password: dbPassword,
//                database: dbName,
//                tls: .require(sslContext) // Qui Swift sa esattamente cosa deve essere
//            )
//        } else {
//            postgresConfig = SQLPostgresConfiguration(
//                hostname: dbHost,
//                port: dbPort,
//                username: dbUser,
//                password: dbPassword,
//                database: dbName,
//                tls: .disable
//            )
//        }
        
    //app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    
    // DEBUG
    //app.logger.logLevel = .debug
    //app.databases.middleware.use(RouteLoggingMiddleware() as! (any AnyModelMiddleware))

    
    // ================================
    // MIGRAZIONI X FLUENT SOSTITUITO DA REST
    // ================================
    //app.migrations.add(CreateQRCode())
    //app.migrations.add(CreateScan())
    
    // ================================
    // LEAF
    // ================================
    app.views.use(.leaf)
    
    // ================================
    // ROUTES
    // ================================
    try routes(app)
}
