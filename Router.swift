//
//  Router.swift
//  CHTTPParser
//
//  Created by Adriana Elizondo on 2019/7/21.
//

import Kitura
import KituraContracts
import LoggerAPI
import CouchDB

private var database: Database?

func initializeRoutes(app: App) {
    database = app.database
    app.router.get("/menuItems", handler: getMenuItems)
    app.router.post("/menuItem", handler: addItem)
    app.router.delete("/menuItem", handler: deleteItem)
}

private func getMenuItems(completion: @escaping (MenuItemsResponse?,
    RequestError?) -> Void) {
    guard let database = database else {
        return completion(nil, .internalServerError)
    }
    MenuItem.Persistence.getAll(from: database) { items, error in
        return completion(MenuItemsResponse(items: items), error as? RequestError)
    }
}

private func addItem(item: MenuItem, completion: @escaping (MenuItem?,
    RequestError?) -> Void) {
    guard let database = database else {
        return completion(nil, .internalServerError)
    }
    MenuItem.Persistence.save(item, to: database) { (intem, error) in
        return completion(item, error as? RequestError)
    }
}

private func deleteItem(id: String, completion: @escaping
    (RequestError?) -> Void) {
    
    guard let database = database else {
        return completion(.internalServerError)
    }
    
    MenuItem.Persistence.delete(id, from: database) { (error) in
        return completion(error as? RequestError)
    }
}
