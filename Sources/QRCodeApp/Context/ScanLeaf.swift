//
//  ScanLeaf.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 31/12/25.
//


struct ScanLeaf: Encodable {
    let id: String
    let qrId: String
    let ipAddress: String
    let userAgent: String
    let createdAt: String
}

struct ScanListContext: Encodable {
    let title: String
    let scans: [ScanLeaf]
}
