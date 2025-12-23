//
//  SignupContext.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 19/12/25.
//

import Vapor
import Leaf


struct SignupContext: Content {
    let globalSettings: GlobalContext
    let someHomeSpecificData: SignupData
}

struct SignupData: Content {
    let title: String
    let subtitle: String
}
