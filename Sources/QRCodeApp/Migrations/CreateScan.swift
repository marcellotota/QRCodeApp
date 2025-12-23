//
//  CreateScan.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 22/12/25.
//


import Fluent

struct CreateScan: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("scans")
            .id()
            .field("qr_code_id", .uuid, .required, .references("qrcodes", "id"))
            .field("timestamp", .datetime, .required)
            .field("ip_address", .string, .required)
            .field("user_agent", .string, .required)
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("scans").delete()
    }
}
