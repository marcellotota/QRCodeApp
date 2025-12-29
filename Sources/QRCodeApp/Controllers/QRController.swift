//
//  QRController.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 22/12/25.
//

import Vapor
import Fluent
import Leaf
import QRCodeGenerator

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
        
        
        // 🚫 CANCELLA
        qr.post(":id", "delete", use: delete)

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
            let svg: String

            do {
                let qrCode = try QRCodeGenerator.QRCode.encode(
                    text: dynamicURL,
                    ecl: QRCodeECC.medium
                )
                svg = qrCode.toSVGString(border: 4)
            } catch {
                print("❌ Errore generazione QR:", error)
                svg = ""
            }

            return QRLeaf(
                id: qr.id!.uuidString,
                targetURL: qr.targetURL,
                dynamicURL: dynamicURL,
                qrBase64: Data(svg.utf8).base64EncodedString(), // <- rinominato
                hasQR: !svg.isEmpty
            )

        }

        let context = QRListContext(title: "QR Codes", qrs: leafQrs, errorMessage: "")
        return try await req.view.render("qrlist", context)
    }

    // MARK: - FORM CREAZIONE
    func showForm(req: Request) throws -> EventLoopFuture<View> {
        req.view.render("create_qr", ["title": "Crea QR Code"])
    }

    // MARK: - CREA QR + RENDER
    func createLeaf(req: Request) async throws -> View {
        guard let targetURL = req.query[String.self, at: "url"] else {
            throw Abort(.badRequest, reason: "Parametro 'url' mancante")
        }

        let qrCodeModel = QRCode(targetURL: targetURL)
        try await qrCodeModel.save(on: req.db)

        guard let id = qrCodeModel.id else {
            throw Abort(.internalServerError)
        }

        let host = req.application.http.server.configuration.hostname
        let port = req.application.http.server.configuration.port
        let dynamicURL = "\(host):\(port)/qr/\(id)"

        // genera SVG QR compatibile Linux
        let qrCode = try QRCodeGenerator.QRCode.encode(
            text: dynamicURL,
            ecl: QRCodeECC.medium)
        let svg = qrCode.toSVGString(border: 4)

        return try await req.view.render("create_qr", [
            "title": "Crea QR Code",
            "qrBase64": Data(svg.utf8).base64EncodedString(), // Base64 SVG
            "targetURL": targetURL,
            "dynamicURL": dynamicURL
        ])
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
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Parametro 'id' mancante")
        }

        let newURL: String
        do {
            newURL = try req.content.get(String.self, at: "url")
        } catch {
            throw Abort(.badRequest, reason: "Parametro 'url' mancante")
        }

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
    
    // MARK: - ELIMINA QR
    func delete(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: UUID.self),
              let qr = try await QRCode.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let host = req.application.http.server.configuration.hostname
        let port = req.application.http.server.configuration.port


        do {
            // elimina le scansioni collegate
            try await Scan.query(on: req.db)
                .filter(\.$qrCode.$id == qr.id!) // Assicurati che la relazione sia corretta
                .delete()

            // elimina il QR
            try await qr.delete(on: req.db)

        } catch {
            let qrs = try await QRCode.query(on: req.db)
                .sort(\.$createdAt, .descending)
                .all()

            let host = req.application.http.server.configuration.hostname
            let port = req.application.http.server.configuration.port

            let leafQrs: [QRLeaf] = qrs.map { qr in
                let dynamicURL = "\(host):\(port)/qr/\(qr.id!.uuidString)"
                return QRLeaf(
                    id: qr.id!.uuidString,
                    targetURL: qr.targetURL,
                    dynamicURL: dynamicURL,
                    qrBase64: "",
                    hasQR: false
                )
            }

            let context = QRListContext(title: "QR Codes", qrs: leafQrs, errorMessage: String(describing: error))
            return try await req.view.render("qrlist", context)
        }

        // ricarica la lista aggiornata senza errori
        let qrs = try await QRCode.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()

        let leafQrs: [QRLeaf] = qrs.map { qr in
            let dynamicURL = "\(host):\(port)/qr/\(qr.id!.uuidString)"
            return QRLeaf(
                id: qr.id!.uuidString,
                targetURL: qr.targetURL,
                dynamicURL: dynamicURL,
                qrBase64: "",
                hasQR: false
            )
        }

        let context = QRListContext(title: "QR Codes", qrs: leafQrs, errorMessage: nil)
        return try await req.view.render("qrlist", context)
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
    let errorMessage: String?  // <- nuovo
}

