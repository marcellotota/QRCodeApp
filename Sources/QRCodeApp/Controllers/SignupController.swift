//
//  SignupController.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 19/12/25.
//


import Vapor

struct SignupController: RouteCollection {
    
    let signupData = SignupData(
        title: "QR-Code | Sign-up page",
        subtitle: "controller per sign-up"
    )
    
    
    func boot(routes: any RoutesBuilder) throws {
        routes.get("signup") { req async throws -> View in
            let global = req.globalContext()
            let context = SignupContext(globalSettings: global, someHomeSpecificData: self.signupData)
            return try await req.view.render("signup", context)
        }
    }
}
