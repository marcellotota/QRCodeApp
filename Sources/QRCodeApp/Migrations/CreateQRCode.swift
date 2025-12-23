//
//  CreateQRCode.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 22/12/25.
//


import Fluent

struct CreateQRCode: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("qrcodes")
            .id()
            .field("target_url", .string, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("qrcodes").delete()
    }
}
