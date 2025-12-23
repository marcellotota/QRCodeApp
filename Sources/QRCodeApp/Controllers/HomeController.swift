//
//  HomeController.swift
//
//  Created by Tota Marcello on 19/12/25.
//

import Vapor

struct HomeController: RouteCollection {
    
    let homeData = HomeData(
        title: " | Home page",
        subtitle: "controller per home page"
    )

    func boot(routes: any RoutesBuilder) throws {
        routes.get { req async throws -> View in
            let global = req.globalContext()
            let context = HomeContext(globalSettings: global, someHomeSpecificData: self.homeData)
            return try await req.view.render("home", context)
        }
    }
}

