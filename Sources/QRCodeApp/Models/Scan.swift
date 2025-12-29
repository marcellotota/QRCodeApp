//
//  Scan.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 22/12/25.
//


import Fluent
import Vapor

final class Scan: Model, Content {
    static let schema = "scans"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "qr_code_id")
    var qrCode: QRCode  // relazione con QRCode

    @Field(key: "ip_address")
    var ipAddress: String

    @Field(key: "user_agent")
    var userAgent: String

    init() { }

    init(id: UUID? = nil, qrCodeID: UUID, ipAddress: String, userAgent: String) {
        self.id = id
        self.$qrCode.id = qrCodeID
        self.ipAddress = ipAddress
        self.userAgent = userAgent
    }
}


extension Scan: @unchecked Sendable {}
