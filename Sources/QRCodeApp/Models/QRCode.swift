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

    // ❌ non forzare immutabilità
    @ID(key: .id)
    var id: UUID?

    @Field(key: "target_url")
    var targetURL: String

    @Field(key: "created_at")
    var createdAt: Date

    @Children(for: \.$qrCode)
    var scans: [Scan]

    init() {}

    init(id: UUID? = nil, targetURL: String, createdAt: Date = Date()) {
        self.id = id
        self.targetURL = targetURL
        self.createdAt = createdAt
    }
}

// Disabilitiamo l’inferenza Sendable
extension QRCode: @unchecked Sendable {}
