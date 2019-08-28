//
//  MenuItem.swift
//  CHTTPParser
//
//  Created by Adriana Elizondo on 2019/7/21.
//

import Foundation
import CouchDB

struct MenuItem: Document{
    let _id: String?
    let _rev: String?
    
    var itemName: String
    var price: Float
    var imageUrl: String
    var category: Category
}
