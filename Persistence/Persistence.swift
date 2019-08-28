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
    static func createIndexForUsers(in database: Database, with request: IndexRequest, with completion: @escaping (IndexResponse?, Error?) -> Void) {
        database.createIndex(parameters: request) { (response, error) in
            completion(response, error)
        }
    }
    static func queryExistingUsers(from database: Database, with email: String, with completion: @escaping (User?) -> Void) {
        var findRequest = FindRequest<[String: String]>()
        let selector = ["email": email]
        findRequest.selector = selector
        findRequest.use_index = "user-doc/user-email-index"
        database.find(parameters: findRequest) { (response: FindResponse<User>?, error) in
            if let response = response {
                return completion(response.docs?.first)
            }
            completion(nil)
        }
    }
    static func getSingle(from database: Database, with itemID: String, callback:
        @escaping (_ items: T?, _ error: Error?) -> Void) {
        database.retrieve(itemID) { (item: T?, error: CouchDBError?) in
            guard item != nil, let _ = item?._rev else {
                Log.error("Error retrieving document: \(String(describing:error))")
                return callback(nil, error)
            }
            callback(item, nil)
        }
    }
    static func getSingle(from database: Database, with keyValue: [String: String], callback:
        @escaping (_ items: T?, _ error: Error?) -> Void) {
       
    }
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
    
    static func update(_ item: T, in database: Database, to newItem: T,
                       callback: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        database.update(item._id ?? "", rev: item._rev ?? "", document: newItem) { (response, error) in
            callback(response?.ok ?? false, error)
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

