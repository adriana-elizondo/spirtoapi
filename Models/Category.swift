//
//  Category.swift
//  CHTTPParser
//
//  Created by Adriana Elizondo on 2019/7/29.
//

import Foundation
import CouchDB

struct Category: Document{
    let _id: String?
    let _rev: String?
    
    var categoryName: String
}
