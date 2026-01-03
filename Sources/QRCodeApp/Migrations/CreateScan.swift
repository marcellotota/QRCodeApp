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
            .field("qr_code_id", .uuid, .required,
                   .references("qrcodes", "id", onDelete: .cascade))
            .field("ip_address", .string)
            .field("user_agent", .string)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("scans").delete()
    }
}
