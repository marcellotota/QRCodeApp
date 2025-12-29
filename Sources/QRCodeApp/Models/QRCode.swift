//
//  QRCode.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 22/12/25.
//


import Fluent
import Vapor

final class QRCode: Model, Content {
    static let schema = "qrcodes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "target_url")
    var targetURL: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(targetURL: String) {
        self.targetURL = targetURL
    }
}


// Disabilitiamo l’inferenza Sendable
extension QRCode: @unchecked Sendable {}
