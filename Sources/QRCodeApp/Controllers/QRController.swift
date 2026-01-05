//
//  QRController.swift
//  QRCodeApp
//

import Vapor
import Leaf
import QRCodeGenerator

struct QRController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let qr = routes.grouped("qr")

        // 📄 LISTA
        qr.get("", use: list)

        // ➕ CREAZIONE
        qr.get("new", use: showForm)
        qr.post("createLeaf", use: createLeaf) // POST invece di GET


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

    // MARK: - Helper Supabase REST
    private func supabaseRequest(_ req: Request, path: String, method: HTTPMethod = .GET, body: [String: Any]? = nil) async throws -> ClientResponse {
        let url = URI(string: "\(Environment.get("SUPABASE_URL")!)/rest/v1/\(path)")

        return try await req.client.send(method, to: url) { request in
            request.headers.add(name: "apikey", value: Environment.get("SUPABASE_API_KEY")!)
            request.headers.add(name: "Authorization", value: "Bearer \(Environment.get("SUPABASE_API_KEY")!)")
            request.headers.add(name: "Content-Type", value: "application/json")

            if let body = body {
                // Serializza in Data JSON
                request.body = try .init(data: JSONSerialization.data(withJSONObject: body))
            }
        }
    }


    // MARK: - LISTA QR
    func list(req: Request) async throws -> View {
        do {
            let response = try await supabaseRequest(req, path: "rpc/get_qrcodes_sorted")
            guard response.status == .ok else {
                throw Abort(.internalServerError, reason: "Errore Supabase: \(response.status)")
            }

            struct QRCodeResponse: Decodable {
                let id: UUID
                let target_url: String
                let created_at: String?
            }

            let qrs = try response.content.decode([QRCodeResponse].self)
            let baseURL = publicBaseURL(req)

            let leafQrs: [QRLeaf] = qrs.map { qr in
                let dynamicURL = "\(baseURL)/qr/\(qr.id.uuidString)"
                var svg = ""
                do {
                    let qrCode = try QRCodeGenerator.QRCode.encode(text: dynamicURL, ecl: .medium)
                    svg = qrCode.toSVGString(border: 4)
                } catch {
                    req.logger.error("❌ QR generation failed: \(String(reflecting: error))")
                }
                return QRLeaf(
                    id: qr.id.uuidString,
                    targetURL: qr.target_url,
                    dynamicURL: dynamicURL,
                    qrBase64: Data(svg.utf8).base64EncodedString(),
                    hasQR: !svg.isEmpty
                )
            }

            let context = QRListContext(title: "QR Codes", qrs: leafQrs, errorMessage: nil)
            return try await req.view.render("qrlist", context)

        } catch {
            req.logger.error("❌ Error fetching QR codes: \(String(reflecting: error))")
            throw error
        }
    }

    // MARK: - FORM CREAZIONE
    func showForm(req: Request) async throws -> View {
        try await req.view.render("create_qr", ["title": "Crea QR Code"])
    }

    // MARK: - CREA QR + RENDER
    struct CreateQRRequest: Content {
        let url: String
    }

    func createLeaf(req: Request) async throws -> View {
        let data = try req.content.decode(CreateQRRequest.self)
        let body: [String: Any] = ["target_url": data.url]

        let _ = try await req.supabaseRequest(path: "qrcodes", method: .POST, body: body)

        let dynamicURL = "\(publicBaseURL(req))/qr/new-id" // id reale se lo leggi dalla risposta
        let qrCode = try QRCodeGenerator.QRCode.encode(text: dynamicURL, ecl: .medium)
        let svg = qrCode.toSVGString(border: 4)

        return try await req.view.render("create_qr", [
            "title": "Crea QR Code",
            "qrBase64": Data(svg.utf8).base64EncodedString(),
            "targetURL": data.url,
            "dynamicURL": dynamicURL
        ])
    }



    // MARK: - FORM MODIFICA
    func editForm(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }

        let response = try await supabaseRequest(req, path: "qrcodes?id=eq.\(id.uuidString)")
        guard response.status == .ok else { throw Abort(.notFound) }

        struct QRCodeResponse: Decodable {
            let id: UUID
            let target_url: String
        }

        guard let qr = try response.content.decode([QRCodeResponse].self).first else {
            throw Abort(.notFound)
        }

        return try await req.view.render("qr_edit", [
            "title": "Modifica QR Code",
            "id": qr.id.uuidString,
            "targetURL": qr.target_url
        ])
    }

    // MARK: - SALVA MODIFICA
    func update(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
        let newURL = try req.content.get(String.self, at: "url")

        let _ = try await supabaseRequest(
            req,
            path: "qrcodes?id=eq.\(id.uuidString)",
            method: .PATCH,
            body: ["target_url": newURL]
        )

        return req.redirect(to: "/qr")
    }

    // MARK: - REDIRECT + TRACKING
    func redirect(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }

        // Recupera QR
        let response = try await supabaseRequest(req, path: "qrcodes?id=eq.\(id.uuidString)")
        guard response.status == .ok else { throw Abort(.notFound) }

        struct QRCodeResponse: Decodable {
            let id: UUID
            let target_url: String
        }
        guard let qr = try response.content.decode([QRCodeResponse].self).first else {
            throw Abort(.notFound)
        }

        // Salva scan
        let scanBody: [String: Any] = [
            "qr_code_id": id.uuidString,
            "ip_address": req.remoteAddress?.ipAddress ?? "unknown",
            "user_agent": req.headers.first(name: .userAgent) ?? "unknown"
        ]
        _ = try await supabaseRequest(req, path: "scans", method: .POST, body: scanBody)

        return req.redirect(to: qr.target_url)
    }

    // MARK: - ELIMINA QR
    func delete(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }

        _ = try await supabaseRequest(req, path: "qrcodes?id=eq.\(id.uuidString)", method: .DELETE)
        _ = try await supabaseRequest(req, path: "scans?qr_code_id=eq.\(id.uuidString)", method: .DELETE)

        return try await list(req: req)
    }

    // MARK: - LISTA SCANSIONI
    func listScans(req: Request) async throws -> View {
        let response = try await supabaseRequest(req, path: "scans?select=*,qr_code(*)&order=created_at.desc")
        guard response.status == .ok else { throw Abort(.internalServerError) }

        struct ScanResponse: Decodable {
            let id: UUID
            let ip_address: String
            let user_agent: String
            let created_at: String?
            let qr_code: QRCodeNested
        }
        struct QRCodeNested: Decodable {
            let target_url: String
        }

        let scans = try response.content.decode([ScanResponse].self)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "it_IT")

        let context = ScanListContext(
            title: "Scansioni QR Codes",
            scans: scans.map { scan in
                ScanLeaf(
                    id: scan.id.uuidString,
                    qrId: scan.qr_code.target_url,
                    ipAddress: scan.ip_address,
                    userAgent: scan.user_agent,
                    createdAt: scan.created_at.flatMap { formatter.date(from: $0) }.map { formatter.string(from: $0) } ?? "—"
                )
            }
        )

        return try await req.view.render("scans", context)
    }
}

// MARK: - Leaf Contexts
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
    let errorMessage: String?
}
