//
//  Application.swift
//  CHTTPParser
//
//  Created by Adriana Elizondo on 2019/7/20.
//

import Foundation
import Kitura
import LoggerAPI
import KituraOpenAPI
import CouchDB

public class App {
    var client: CouchDBClient?
    var database: Database?
    
    let router = Router()
    
    private func postInit() {
        let connectionProperties = ConnectionProperties(host: "127.0.0.1",
                                                        port: 5984,
                                                        secured: false)
        client = CouchDBClient(connectionProperties: connectionProperties)
        client!.retrieveDB("spirtodb") { database, error in
            guard let database = database else {
                Log.info("Could not retrieve Spirto database: "
                    + "\(String(describing: error?.localizedDescription)) "
                    + "- attempting to create new one.")
                self.createNewDatabase()
                return
            }
    
            Log.info("Database located - loading...")
            self.finalizeRoutes(with: database)
        }
        
        KituraOpenAPI.addEndpoints(to: router)
    }
    
    private func createNewDatabase() {
        client?.createDB("spirtodb") { database, error in
            guard let database = database else {
                Log.error("Could not create new database: "
                    + "(\(String(describing: error?.localizedDescription))) "
                    + "- spirtodb routes not created")
                return
            }
            self.finalizeRoutes(with: database)
        }
    }
    
    private func finalizeRoutes(with database: Database) {
        self.database = database
        initializeRoutes(app: self)
    }
    
    public func run() {
        postInit()
        Kitura.addHTTPServer(onPort: 8080, with: router)
        Kitura.run()
    }
}
