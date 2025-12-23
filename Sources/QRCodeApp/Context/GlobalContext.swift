//
//  GlobalContext.swift
//
//  Created by Tota Marcello on 19/12/25.
//

import Vapor

struct GlobalContext: Authenticatable, Encodable, Content {
    let isAdmin: Bool
    let userName: String
    let email: String
    let preferredUsername: String
    let oid: String
    let photoURL: String?
    let upn: String
}

