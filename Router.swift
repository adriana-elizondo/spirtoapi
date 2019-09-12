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

protocol RouterResponse where Self: Codable{
    associatedtype T: Document
    var itemsReturned: [T] {get set}
}

struct CommonResponse<T: Document>: RouterResponse{
    var itemsReturned: [T]
}

struct CommonSingleResponse<T: Document>: Codable{
    var itemReturned: T
}

private var database: Database?

typealias RouterCompletion = (RouterResponse?,
    RequestError?) -> Void

func initializeRoutes(app: App) {
    database = app.database
    //items
    app.router.get("/menuItems", handler: getMenuItems)
    app.router.post("/menuItem", handler: addMenuItem)
    app.router.put("/menuItemUpdate", handler: updateItem)
    app.router.delete("/menuItem", handler: deleteMenuItem)
    
    //categories
    app.router.get("/categories", handler: getCategories)
    app.router.post("/category", handler: addCategories)
    app.router.delete("/category", handler: deleteCategory)
    
    //addressess
    app.router.get("/allAddressess", handler: getAllAddresses)
    app.router.get("/addressess", handler: getAddresses)
    app.router.post("/address", handler: addAddress)
    app.router.delete("/address", handler: deleteAddress)
    
    //user
    app.router.get("/user", handler: getUser)
    app.router.get("/allUsers", handler: getAllUsers)
    app.router.post("/user", handler: addUser)
    app.router.post("/user_index", handler: addUserIndex)
    app.router.put("/userUpdate", handler: updateUser)
    app.router.delete("/user", handler: deleteUser)
}

//Menu items
private func getMenuItems(completion: @escaping (CommonResponse<MenuItem>?,
    RequestError?) -> Void) {
    genericGetItems(completion: completion)
}
private func updateItem(id: String, item: MenuItem, completion: @escaping (CommonResponse<MenuItem>?,
    RequestError?) -> Void){
    genericUpdate(with: id, to: item) { (response, error) in
        if let itemResponse = response {
            return completion(itemResponse, nil)
        }
        completion(nil, RequestError.notFound)
    }
}
private func addMenuItem(item: MenuItem, completion: @escaping (MenuItem?,
    RequestError?) -> Void){
    genericAddItem(item: item, completion: completion)
}

private func deleteMenuItem(id: String, completion: @escaping (RequestError?) -> Void){
    let _: MenuItem? = genericDeleteItem(itemId: id, completion: completion)
}

//Categories
private func getCategories(completion: @escaping (CommonResponse<Category>?,
    RequestError?) -> Void) {
    genericGetItems(completion: completion)
}

private func addCategories(item: Category, completion: @escaping (Category?,
    RequestError?) -> Void){
    genericAddItem(item: item, completion: completion)
}

private func deleteCategory(id: String, completion: @escaping (RequestError?) -> Void){
    let _: Category? = genericDeleteItem(itemId: id, completion: completion)
}

//Addressess
private func getAllAddresses(completion: @escaping (CommonResponse<Address>?,
    RequestError?) -> Void) {
    genericGetItems(completion: completion)
}
private func getAddresses(email: String, completion: @escaping (CommonResponse<Address>?,
    RequestError?) -> Void) {
    getUser(email: email) { (user, error) in
        guard error == nil else {completion(nil, error); return}
        return completion(CommonResponse(itemsReturned: user?.itemReturned.addresses ?? []), error)
    }
}
private func addAddress(item: AddressPostParameters, completion: @escaping (CommonSingleResponse<Address>?,
    RequestError?) -> Void){
    getUserWithEmail(with: item.userEmail) { (user, error) in
        guard var newuser = user?.itemReturned else { return completion(nil, error)}
        genericAddItem(item: item.address, completion: { (address, error) in
            if let address = address {
                if newuser.addresses == nil {
                    newuser.addresses = [Address]()
                }
                newuser.addresses?.append(address)
                updateUser(id: newuser._id ?? "", user: newuser, completion: { (user, error) in
                    guard error == nil else { return completion(nil, error) }
                    return completion(CommonSingleResponse(itemReturned: address), nil)
                })
            }
            return completion(nil, error)
        })
    }
   
}

private func deleteAddress(id: String, completion: @escaping (RequestError?) -> Void){
    let _: Address? = genericDeleteItem(itemId: id, completion: completion)
}

//User
private func getUser(email: String, completion: @escaping (CommonSingleResponse<User>?,
    RequestError?) -> Void) {
    getUserWithEmail(with: email, completion: completion)
}

private func getUserWithEmail(with email: String,
                              completion: @escaping (CommonSingleResponse<User>?,
    RequestError?) -> Void) {
    guard let database = database else {
        return completion(nil, RequestError.internalServerError)
    }
    Persistence<User>.queryExistingUsers(from: database, with: email) { (existingUser) in
        if let user = existingUser {
            return completion(CommonSingleResponse(itemReturned: user), nil)
        }
        
        return completion(nil, RequestError.expectationFailed)
    }
}

private func getAllUsers(completion: @escaping (CommonResponse<User>?,
    RequestError?) -> Void) {
    genericGetItems(completion: completion)
}

private func updateUser(id: String, user: User, completion: @escaping (CommonResponse<User>?,
    RequestError?) -> Void) {
    genericUpdate(with: id, to: user) { (response, error) in
        if let userResponse = response {
           return completion(userResponse, nil)
        }
        completion(nil, RequestError.notFound)
    }
}

private func addUser(item: User, completion: @escaping (CommonSingleResponse<User>?,
    RequestError?) -> Void){
    guard let database = database else {
        return completion(nil, RequestError.internalServerError)
    }
    Persistence<User>.queryExistingUsers(from: database, with: item.email) { (existingUser) in
        guard existingUser == nil else {
            var userToUpdateTo = item
            userToUpdateTo.addresses = existingUser?.addresses
            return updateUser(id: existingUser?._id ?? "" , user: userToUpdateTo, completion: { (response, error) in
                if let updatedUser = response?.itemsReturned.first {
                   return completion(CommonSingleResponse(itemReturned: updatedUser), nil)
                }
                
                return completion(nil, error)
            })
        }
        
        genericAddItem(item: item, completion: { (user, error) in
            if let user = user {
                return completion(CommonSingleResponse(itemReturned: user), nil)
            }
            
            return completion(nil, error)
        })
    }
}

private func addUserIndex(index: UserIndex, completion: @escaping (IndexResponse?,
    RequestError?) -> Void){
    guard let database = database else {
        return completion(nil, RequestError.internalServerError)
    }
    var indexRequest = IndexRequest()
    indexRequest.index = IndexRequest.Index(with: index.fields)
    indexRequest.name = index.indexName
    indexRequest.name = index.designDocName
    Persistence<User>.createIndexForUsers(in: database, with: indexRequest) { (result, error) in
        completion(result, error as? RequestError)
    }
}

private func deleteUser(id: String, completion: @escaping (RequestError?) -> Void){
    let _: User? = genericDeleteItem(itemId: id, completion: completion)
}

////
private func genericGetItem<R:Document>(with id: String, completion: @escaping (CommonResponse<R>?,
    Error?) -> Void) {
    guard let database = database else {
        return completion(nil, RequestError.internalServerError)
    }
    Persistence<R>.getSingle(from: database, with: id) { (document, error) in
        guard error == nil else {completion(nil, error as? RequestError); return}
        return completion(CommonResponse(itemsReturned: [document!]), error as? RequestError)
    }
}

private func genericUpdate<R:Document>(with id: String, to new: R, completion: @escaping (CommonResponse<R>?,
    Error?) -> Void) {
    guard let database = database else {
        return completion(nil, RequestError.internalServerError)
    }
    
    Persistence<R>.getSingle(from: database, with: id) { (document, error) in
        guard error == nil && document != nil else {
            completion(nil, error as? RequestError)
            return
        }
        
        Persistence<R>.update(document!, in: database, to: new) { (success, error) in
            if (success == true ) {
                return completion(CommonResponse(itemsReturned: [new]), error as? RequestError)
            }
            if (error != nil) { completion(nil, error as? RequestError) }
        }
        
    }
}

private func genericGetItems<R: Document>(completion: @escaping (CommonResponse<R>?,
    RequestError?)-> Void){
    guard let database = database else {
        return completion(nil, .internalServerError)
    }
    
    Persistence<R>.getAll(from: database) { items, error in
        guard error == nil else {completion(nil, error as? RequestError); return}
        return completion(CommonResponse(itemsReturned: items!), error as? RequestError)
    }
}

private func genericAddItem<R: Document>(item: R, completion: @escaping (R?,
    RequestError?) -> Void) {
    guard let database = database else {
        return completion(nil, .internalServerError)
    }
    Persistence<R>.save(item, to: database) { (item, error) in
        return completion(item, error as? RequestError)
    }
}

private func genericDeleteItem<R: Document>(itemId: String, completion: @escaping (RequestError?) -> Void) -> R?{
    
    guard let database = database else {
        completion(.internalServerError)
        return nil
    }
    
    Persistence<R>.delete(itemId, from: database) { (error) in
        completion(error as? RequestError)
    }
    
    return nil
}


