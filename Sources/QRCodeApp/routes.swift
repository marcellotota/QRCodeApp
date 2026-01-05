import Vapor

func routes(_ app: Application) throws {
    
    // Route ping pulita, senza Leaf o redirect
        app.get("ping") { req -> String in
            return "PONG 🚀"
        }

    // Qui registri i tuoi controller
    try app.register(collection: HomeController())
    try app.register(collection: DocumentsController())
    try app.register(collection: SignupController())
    try app.register(collection: QRController())
}
