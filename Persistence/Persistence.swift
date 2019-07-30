//
//  MenuItemPersistence.swift
//  SpirtoAPI
//
//  Created by Adriana Elizondo on 2019/7/21.
//

import Foundation
import CouchDB
import LoggerAPI

class Persistence<T: Document>{
    static func getAll(from database: Database, callback:
        @escaping (_ items: [T]?, _ error: Error?) -> Void) {
        database.retrieveAll(includeDocuments: true) { documents, error in
            guard let documents = documents else {
                Log.error("Error retrieving all documents: \(String(describing: error))")
                return callback(nil, error)
            }
            let items = documents.decodeDocuments(ofType: T.self)
            callback(items, nil)
        }
    }
    
    static func save(_ item: T, to database: Database, callback:
        @escaping (_ item: T?, _ error: Error?) -> Void) {
        database.create(item) { document, error in
            guard let document = document else {
                Log.error("Error creating new document: \(String(describing: error))")
                return callback(nil, error)
            }
            database.retrieve(document.id, callback: callback)
        }
    }
    
    static func delete(_ itemID: String, from database: Database, callback:
        @escaping (_ error: Error?) -> Void) {
        database.retrieve(itemID) { (item: T?, error: CouchDBError?) in
            guard item != nil, let itemrev = item?._rev else {
                Log.error("Error retrieving document: \(String(describing:error))")
                return callback(error)
            }
            
            database.delete(itemID, rev: itemrev, callback: callback)
        }
    }
}

