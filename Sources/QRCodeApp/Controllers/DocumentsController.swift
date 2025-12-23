//
//  DocumentController.swift
//  QRCodeApp
//
//  Created by Tota Marcello on 19/12/25.
//

import Vapor

struct DocumentsController: RouteCollection {
    
    func fetchDocuments() async throws -> [Document] {
        // per ora leggi i dati finti
        let fakeData: [String: String] = [
            "Roma": "La Città Eterna, famosa per il Colosseo e la sua storia millenaria.",
            "Parigi": "La capitale dell'amore e dell'arte, celebre per la Tour Eiffel e il Louvre.",
            "Berlino": "Una metropoli moderna e vibrante, simbolo della storia contemporanea europea.",
            "Madrid": "Nota per la sua vivace vita notturna, i grandi musei e il Palazzo Reale.",
            "Lisbona": "Città costiera affascinante, famosa per i suoi tram gialli e la musica Fado.",
            "Vienna": "Elegante capitale della musica classica, nota per i suoi palazzi imperiali.",
            "Praga": "La città dalle cento torri, celebre per il suo centro storico medievale.",
            "Amsterdam": "Famosa per i suoi canali romantici e l'atmosfera cosmopolita.",
            "Stoccolma": "Una splendida capitale costruita su 14 isole nel Mar Baltico.",
            "Atene": "La culla della democrazia, dominata dalla maestosa Acropoli."
        ]
        
        return fakeData.map { key, value in
            Document(title: key, description: value)
        }
    }
    
    func boot(routes: any RoutesBuilder) throws {
        routes.get("documents") { req async throws -> View in
            let global = req.globalContext()
            
            let documents = try await fetchDocuments()
            let documentData = DocumentData(title: " | Documents Page", documenti: documents)
            let context = DocumentsContext(globalSettings: global, someHomeSpecificData: documentData)
            
            return try await req.view.render("documents", context)
        }
    }
}

