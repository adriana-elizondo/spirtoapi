//
//  User.swift
//  CHTTPParser
//
//  Created by Adriana Elizondo on 2019/7/31.
//

import Foundation
import CouchDB

struct User: Document{
    let _id: String?
    let _rev: String?
    
    var name: String
    var email: String
    var phoneNumber: String
    var photoUrl: String
    var addresses: [Address]?
}

struct Address: Document{
    let _id: String?
    let _rev: String?
    
    var addressDescription: String
    var city: String
    var latitude: Double
    var longitude: Double
}

struct UserIndex: Codable {
    var fields: [String]
    var indexName: String
    var designDocName: String
}
