//
//  HomeContext.swift
//  GestionaleAutoSupabase
//
//  Created by Tota Marcello on 24/11/25.
//

import Vapor
import Leaf


struct HomeContext: Content {
    let globalSettings: GlobalContext
    let someHomeSpecificData: HomeData
}

struct HomeData: Content {
    let title: String
    let subtitle: String
}
