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

