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

        // 📄 LISTA
        qr.get("", use: list)

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
        
        // 📊 LISTA SCANSIONI
        qr.get("scans", use: listScans)
    }

    // MARK: - Helper URL pubblico (Render-safe)
    private func publicBaseURL(_ req: Request) -> String {
        let scheme: String

        if let forwarded = req.headers.first(name: .xForwardedProto) {
            scheme = forwarded
        } else {
            scheme = req.application.environment == .production ? "https" : "http"
        }

        let host = req.headers.first(name: .host) ?? "localhost"
        return "\(scheme)://\(host)"
    }


    // MARK: - LISTA QR
    func list(req: Request) async throws -> View {

        do {
            // Recupero QR ordinati per data (se presente)
            let qrs = try await QRCode.query(on: req.db)
                //.sort(\.$createdAt, .descending)
                .all()

            let baseURL = publicBaseURL(req)

            let leafQrs: [QRLeaf] = qrs.compactMap { qr in
                // Evita crash se l'id è nil
                guard let id = qr.id else {
                    req.logger.error("❌ QRCode senza ID trovato nel database")
                    return nil
                }

                let dynamicURL = "\(baseURL)/qr/\(id.uuidString)"

                var svg = ""
                do {
                    let qrCode = try QRCodeGenerator.QRCode.encode(
                        text: dynamicURL,
                        ecl: QRCodeECC.medium
                    )
                    svg = qrCode.toSVGString(border: 4)
                } catch {
                    req.logger.error("❌ QR generation failed: \(String(reflecting: error))")
                }

                return QRLeaf(
                    id: id.uuidString,
                    targetURL: qr.targetURL,
                    dynamicURL: dynamicURL,
                    qrBase64: Data(svg.utf8).base64EncodedString(),
                    hasQR: !svg.isEmpty
                )
            }

            let context = QRListContext(
                title: "QR Codes",
                qrs: leafQrs,
                errorMessage: nil
            )

            return try await req.view.render("qrlist", context)

        } catch {
            // 🔥 MOSTRA l’errore reale nei log (fondamentale)
            req.logger.error("❌ Error fetching QR codes: \(String(reflecting: error))")
            throw error
        }
    }


    // MARK: - FORM CREAZIONE
    func showForm(req: Request) async throws -> View {
        try await req.view.render("create_qr", ["title": "Crea QR Code"])
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

        let dynamicURL = "\(publicBaseURL(req))/qr/\(id.uuidString)"
        let qrCode = try QRCodeGenerator.QRCode.encode(text: dynamicURL, ecl: .medium)
        let svg = qrCode.toSVGString(border: 4)

        return try await req.view.render("create_qr", [
            "title": "Crea QR Code",
            "qrBase64": Data(svg.utf8).base64EncodedString(),
            "targetURL": targetURL,
            "dynamicURL": dynamicURL
        ])
    }

    // MARK: - FORM MODIFICA
    func editForm(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
        guard let qr = try await QRCode.find(id, on: req.db) else { throw Abort(.notFound) }

        return try await req.view.render("qr_edit", [
            "title": "Modifica QR Code",
            "id": qr.id!.uuidString,
            "targetURL": qr.targetURL
        ])
    }

    // MARK: - SALVA MODIFICA
    func update(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
        let newURL = try req.content.get(String.self, at: "url")
        guard let qr = try await QRCode.find(id, on: req.db) else { throw Abort(.notFound) }

        qr.targetURL = newURL
        try await qr.save(on: req.db)
        return req.redirect(to: "/qr")
    }

    // MARK: - REDIRECT + TRACKING
    func redirect(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
        guard let qr = try await QRCode.find(id, on: req.db) else { throw Abort(.notFound) }

        let scan = Scan(
            qrCodeID: id,
            ipAddress: req.remoteAddress?.ipAddress ?? "unknown",
            userAgent: req.headers.first(name: .userAgent) ?? "unknown"
        )
        try await scan.save(on: req.db)
        return req.redirect(to: qr.targetURL)
    }

    // MARK: - ELIMINA QR
    func delete(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: UUID.self),
              let qr = try await QRCode.find(id, on: req.db) else { throw Abort(.notFound) }

        do {
            try await Scan.query(on: req.db).filter(\.$qrCode.$id == qr.id!).delete()
            try await qr.delete(on: req.db)
        } catch {
            req.logger.error("❌ Delete failed: \(error)")
        }

        let qrs = try await QRCode.query(on: req.db).sort(\.$createdAt, .descending).all()
        let baseURL = publicBaseURL(req)
        let leafQrs = qrs.map {
            QRLeaf(id: $0.id!.uuidString, targetURL: $0.targetURL, dynamicURL: "\(baseURL)/qr/\($0.id!.uuidString)", qrBase64: "", hasQR: false)
        }

        return try await req.view.render("qrlist", QRListContext(title: "QR Codes", qrs: leafQrs, errorMessage: nil))
    }
    
    // MARK: - LISTA SCANSIONI
    func listScans(req: Request) async throws -> View {
        let scans = try await Scan.query(on: req.db)
            .with(\.$qrCode)
            .sort(\.$createdAt, .descending)
            .all()
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "it_IT")


        let context = ScanListContext(
            title: "Scansioni QR Codes",
            scans: scans.map { scan in
                ScanLeaf(
                    id: scan.id!.uuidString,
                    qrId: scan.qrCode.targetURL,
                    ipAddress: scan.ipAddress,
                    userAgent: scan.userAgent,
                    createdAt: scan.createdAt.map { formatter.string(from: $0) } ?? "—"
                )
            }

        )

        return try await req.view.render("scans", context)
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

