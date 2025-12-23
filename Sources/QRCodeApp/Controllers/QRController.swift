//
//  QRController.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 22/12/25.
//


import Vapor
import Fluent
import EFQRCode
import Leaf

struct QRController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let qr = routes.grouped("qr")

        // 📄 LISTA QR
        qr.get(use: list)

        // ➕ CREAZIONE
        qr.get("new", use: showForm)
        qr.get("createLeaf", use: createLeaf)

        // ✏️ MODIFICA
        qr.get(":id", "edit", use: editForm)
        qr.post(":id", "edit", use: update)

        // 🔁 REDIRECT DINAMICO
        qr.get(":id", use: redirect)
    }

    // MARK: - LISTA QR
    func list(req: Request) async throws -> View {
        let qrs = try await QRCode.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()

        let host = req.application.http.server.configuration.hostname
        let port = req.application.http.server.configuration.port

        let leafQrs: [QRLeaf] = qrs.map { qr in
            let dynamicURL = "\(host):\(port)/qr/\(qr.id!.uuidString)"
            let base64QR: String
            if let cgImage = EFQRCode.generate(
                for: dynamicURL,
                size: EFIntSize(width: 150, height: 150)
            ), let pngData = pngData(from: cgImage) {
                base64QR = pngData.base64EncodedString()
            } else {
                base64QR = ""
            }

            return QRLeaf(
                    id: qr.id!.uuidString,
                    targetURL: qr.targetURL,
                    dynamicURL: dynamicURL,
                    qrBase64: base64QR,
                    hasQR: !base64QR.isEmpty  // impostiamo un booleano
                )
        }

        let context = QRListContext(title: "QR Codes", qrs: leafQrs)
        return try await req.view.render("qrlist", context)
    }




    // MARK: - FORM CREAZIONE
    func showForm(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("create_qr", [
            "title": "Crea QR Code"
        ])
    }

    // MARK: - CREA QR + RENDER
    func createLeaf(req: Request) throws -> EventLoopFuture<View> {

        guard let targetURL = req.query[String.self, at: "url"] else {
            throw Abort(.badRequest, reason: "Parametro 'url' mancante")
        }

        let qrCode = QRCode(targetURL: targetURL)

        return qrCode.save(on: req.db)
            .flatMapErrorThrowing { error in
                print("💥 DB Error: \(String(reflecting: error))")
                throw Abort(.internalServerError, reason: "Database error")
            }
            .flatMap { _ in
                guard let id = qrCode.id else {
                    return req.eventLoop.future(error: Abort(.internalServerError))
                }

                let host = req.application.http.server.configuration.hostname
                let port = req.application.http.server.configuration.port
                let dynamicURL = "\(host):\(port)/qr/\(id)"

                guard let cgImage = EFQRCode.generate(
                    for: dynamicURL,
                    size: EFIntSize(width: 300, height: 300)
                ) else {
                    return req.eventLoop.future(error: Abort(.internalServerError))
                }

                guard let pngData = pngData(from: cgImage) else {
                    return req.eventLoop.future(error: Abort(.internalServerError))
                }

                let base64QR = pngData.base64EncodedString()

                return req.view.render("create_qr", [
                    "title": "Crea QR Code",
                    "qrBase64": base64QR,
                    "targetURL": targetURL,
                    "dynamicURL": dynamicURL
                ])
            }
    }

    // MARK: - FORM MODIFICA
    func editForm(req: Request) throws -> EventLoopFuture<View> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        return QRCode.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { qr in
                req.view.render("qr_edit", [
                    "title": "Modifica QR Code",
                    "id": qr.id!.uuidString,
                    "targetURL": qr.targetURL
                ])
            }
    }

    // MARK: - SALVA MODIFICA
    func update(req: Request) throws -> EventLoopFuture<Response> {
        // 1️⃣ Prendi l'ID dai parametri
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Parametro 'id' mancante")
        }

        // 2️⃣ Prendi il nuovo URL dal body
        let newURL: String
        do {
            newURL = try req.content.get(String.self, at: "url")
        } catch {
            throw Abort(.badRequest, reason: "Parametro 'url' mancante")
        }

        // 3️⃣ Trova il QR nel DB e aggiorna
        return QRCode.find(id, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "QR Code non trovato"))
            .flatMap { qr in
                qr.targetURL = newURL
                return qr.save(on: req.db).map {
                    req.redirect(to: "/qr")
                }
            }
    }


    // MARK: - REDIRECT + TRACKING
    func redirect(req: Request) throws -> EventLoopFuture<Response> {

        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        return QRCode.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { qr in
                let scan = Scan(
                    qrCodeID: id,
                    ipAddress: req.remoteAddress?.ipAddress ?? "unknown",
                    userAgent: req.headers.first(name: .userAgent) ?? "unknown"
                )

                return scan.save(on: req.db).map {
                    req.redirect(to: qr.targetURL)
                }
            }
    }
}



struct QRLeaf: Encodable {
    let id: String
    let targetURL: String
    let dynamicURL: String
    let qrBase64: String
    let hasQR: Bool
}

struct QRListContext: Encodable {
    let title: String
    let qrs: [QRLeaf]
}
