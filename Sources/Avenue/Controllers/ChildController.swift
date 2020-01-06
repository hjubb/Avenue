import Foundation
import FluentPostgreSQL
import Vapor

struct ChildController<Parent: VaporModel, Child: VaporModel> {
    var keypath: KeyPath<Child, Int>
    
    // MARK: Boot
    func boot(router: Router) throws {
        print("🚀🚀🚀 Adding routes for Prent: \(Parent.name) and Child: \(Child.name)")
        let route = router.grouped(Parent.name.lowercased())
        route.put(Parent.parameter, "\(Child.name)", "add", use: addChild)
        route.delete(Parent.parameter, "\(Child.name)", Child.parameter, "remove", use: removeChild)
        route.get(Parent.parameter, "\(Child.name)", "children", use: getAllChildren)
        route.get(Parent.parameter, "\(Child.name)", Child.parameter, use: getChild)
        route.get("\(Child.name)", Child.parameter, "parent", use: getParent)
    }
    
    
    //MARK: Main
    func addChild(_ req: Request) throws -> Future<Child> {
        guard let ownerId = req.http.headers.firstValue(name: .contentID) else { throw Abort(.unauthorized) }
        return (try req.parameters.next(Parent.self) as! EventLoopFuture<Parent>).flatMap { (parent) -> EventLoopFuture<Child> in
            guard parent.ownerID?.contains(ownerId) ?? false else { throw Abort(.forbidden) }
            return try req.content.decode(Child.self, using: decoderJSON).flatMap { model in
                var newModel = model
                newModel.assignOwner(ownerId)
                return newModel.save(on: req)
            }
        }
    }
    
    func removeChild(_ req: Request) throws -> Future<HTTPResponseStatus> {
        guard let ownerId = req.http.headers.firstValue(name: .contentID) else { throw Abort(.unauthorized) }
        return flatMap(try req.parameters.next(Parent.self) as! EventLoopFuture<Parent>, try req.parameters.next(Child.self) as! EventLoopFuture<Child>) { parent, child -> Future<HTTPResponseStatus> in
            let acctualParent: Fluent.Parent<Child, Parent> = child.parent(self.keypath)
            guard try parent.requireID() == acctualParent.parentID else { throw Abort(.badRequest) }
            guard parent.ownerID?.contains(ownerId) ?? false else { throw Abort(.forbidden) }
            return child.delete(on: req).transform(to: HTTPStatus.noContent)
        }
    }
    
    func getAllChildren(_ req: Request) throws -> Future<[Child]> {
        let pagination = try req.query.decode(Pagination.self)
        let startIndex = pagination.offset ?? 0
        let length = pagination.length ?? 50
        let endIndex = startIndex + length
        
        return (try req.parameters.next(Parent.self) as! EventLoopFuture<Parent>).flatMap { parent -> EventLoopFuture<[Child]> in
            return try parent.children(self.keypath).query(on: req).range(startIndex ..< endIndex).all()
        }
    }
    
    func getChild(_ req: Request) throws -> Future<Child> {
        return map(try req.parameters.next(Parent.self) as! EventLoopFuture<Parent>, try req.parameters.next(Child.self) as! EventLoopFuture<Child>) { parent, child -> Child in
            let acctualParent: Fluent.Parent<Child, Parent> = child.parent(self.keypath)
            guard try parent.requireID() == acctualParent.parentID else { throw Abort(.badRequest) }
            return child
        }
    }
    
    func getParent(_ req: Request) throws -> Future<Parent> {
        return (try req.parameters.next(Child.self) as! EventLoopFuture<Child>).flatMap { child -> EventLoopFuture<Parent> in
            let parent: Fluent.Parent<Child, Parent> = child.parent(self.keypath)
            return parent.get(on: req)
        }
    }
}
