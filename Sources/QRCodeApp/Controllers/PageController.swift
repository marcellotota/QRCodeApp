//
//  PageController.swift
//  VaporVSCodeTest
//
//  Created by Tota Marcello on 19/12/25.
//
import Fluent
import Vapor

struct PageController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get { req async throws -> View in
            try await req.view.render("home", ["title": "Hello Vapor!"])
        }

    }
}
