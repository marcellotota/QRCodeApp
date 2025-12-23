//
//  DocumentsContext.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 19/12/25.
//


import Vapor
import Leaf


struct DocumentsContext: Content {
    let globalSettings: GlobalContext
    let someHomeSpecificData: DocumentData
}

struct DocumentData: Content {
    let title: String
    let documenti: [Document]
}

struct Document: Content {
    let title: String
    let description: String
}
