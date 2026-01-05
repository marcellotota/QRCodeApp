//
//  File.swift
//
//  Created by Tota Marcello on 19/12/25.
//

import Vapor
import Leaf
import AsyncHTTPClient

// MARK: - Estensioni
// MARK: - globalContext()

extension Request {
    func globalContext() -> GlobalContext {

        return GlobalContext(
            isAdmin: (self.session.data["isAdmin"] ?? "false") == "true",
            userName: self.session.data["user"] ?? "No user!!",
            email: self.session.data["userEmail"] ?? "-",
            preferredUsername: self.session.data["preferredUsername"] ?? "-",
            oid: self.session.data["oid"] ?? "-",
            photoURL: self.session.data["photoURL"],   // può essere stringa vuota o nil
            upn: self.session.data["upn"] ?? "-",

        )
    }
}

extension Request {
    var supabaseURL: String { Environment.get("SUPABASE_URL") ?? "" }
    var supabaseKey: String { Environment.get("SUPABASE_API_KEY") ?? "" }

    func supabaseRequest(path: String, method: HTTPMethod = .GET, body: [String: Any]? = nil) async throws -> ClientResponse {
        let url = URI(string: "\(supabaseURL)/rest/v1/\(path)")
        return try await self.client.send(method, to: url) { req in
            req.headers.add(name: "apikey", value: supabaseKey)
            req.headers.add(name: "Authorization", value: "Bearer \(supabaseKey)")
            req.headers.add(name: "Content-Type", value: "application/json")
            if let body = body {
                // Serializza in Data JSON
                req.body = try .init(data: JSONSerialization.data(withJSONObject: body))
            }
        }
    }
}
