import Foundation
import FluentPostgreSQL
import Vapor

struct SiblingController<LHS: VaporSibling, RHS: VaporModel, Pivot: VaporPivot> {
    var keypathLeft: WritableKeyPath<Pivot, Int>
    var keypathRight: WritableKeyPath<Pivot, Int>
    
    // MARK: Boot
    func boot(router: Router) throws {
        print("🚀🚀🚀 Adding routes for siblings LHS: \(LHS.name) and RHS: \(RHS.name)")
        let route = router.grouped(LHS.name.lowercased())
        route.post(LHS.parameter, "\(RHS.name)", RHS.parameter, "attach", use: add)
        route.delete(LHS.parameter, "\(RHS.name)", RHS.parameter, "detach", use: remove)
        route.get(LHS.parameter, "siblings", "\(RHS.name)", use: getAllLHS)
        
        let routeRHS = router.grouped(RHS.name.lowercased())
        routeRHS.get(RHS.parameter, "siblings", "\(LHS.name)", use: getAllRHS)
    }
    
    
    //MARK: Main
    func add(_ req: Request) throws -> Future<HTTPStatus> {
        guard let ownerId = req.http.headers.firstValue(name: .contentID) else { throw Abort(.unauthorized) }
        return flatMap((try req.parameters.next(LHS.self) as! EventLoopFuture<LHS>), (try req.parameters.next(RHS.self) as! EventLoopFuture<RHS>)) { (lhs, rhs) -> Future<HTTPStatus> in
            guard lhs.ownerID == nil || lhs.ownerID?.contains(ownerId) ?? false, rhs.ownerID == nil || rhs.ownerID?.contains(ownerId) ?? false else { throw Abort(.forbidden) }
            return lhs.isAttached(rhs, on: req).map({ isAttached -> EventLoopFuture<Pivot?>? in
                if isAttached { return nil }
                return lhs.attach(rhs, on: req)
            }).transform(to: .created)
        }
    }
    
    func remove(_ req: Request) throws -> Future<HTTPResponseStatus> {
        guard let ownerId = req.http.headers.firstValue(name: .contentID) else { throw Abort(.unauthorized) }
        return flatMap(try req.parameters.next(LHS.self) as! EventLoopFuture<LHS>, try req.parameters.next(RHS.self) as! EventLoopFuture<RHS>) { (lhs, rhs) -> Future<HTTPResponseStatus> in
            guard lhs.ownerID == nil || lhs.ownerID?.contains(ownerId) ?? false, rhs.ownerID == nil || rhs.ownerID?.contains(ownerId) ?? false else { throw Abort(.forbidden) }
            return lhs.detach(rhs, on: req).transform(to: .ok)
        }
    }
    
    func getAllLHS(_ req: Request) throws -> Future<[RHS]> {
        let pagination = try req.query.decode(Pagination.self)
        let startIndex = pagination.offset ?? 0
        let length = pagination.length ?? 50
        let endIndex = startIndex + length
        
        return (try req.parameters.next(LHS.self) as! EventLoopFuture<LHS>).flatMap { lhs -> EventLoopFuture<[RHS]> in
            return try lhs.siblings(related: RHS.self, through: Pivot.self, self.keypathLeft, self.keypathRight).query(on: req).range(startIndex ..< endIndex).all()
        }
    }
    
    func getAllRHS(_ req: Request) throws -> Future<[LHS]> {
        let pagination = try req.query.decode(Pagination.self)
        let startIndex = pagination.offset ?? 0
        let length = pagination.length ?? 50
        let endIndex = startIndex + length
        
        return (try req.parameters.next(RHS.self) as! EventLoopFuture<RHS>).flatMap { rhs -> EventLoopFuture<[LHS]> in
            return try rhs.siblings(related: LHS.self, through: Pivot.self, self.keypathRight, self.keypathLeft).query(on: req).range(startIndex ..< endIndex).all()
        }
    }
}
