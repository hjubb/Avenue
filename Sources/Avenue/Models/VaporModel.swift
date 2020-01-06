import Foundation
import FluentPostgreSQL
import Vapor

protocol VaporPivot: PostgreSQLPivot & ModifiablePivot & Content & Parameter {}

protocol VaporSibling: VaporModel {
    func isAttached<T: PostgreSQLModel>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<Bool>
    func attach<T: PostgreSQLModel, P: VaporPivot>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<P?>
    func detach<T: PostgreSQLModel>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<Void>
}

protocol VaporModel: PostgreSQLModel & Content & Parameter {
    var ownerID: [String]? { get set }
    func update(_ model: Self) throws
}

extension VaporModel {
    var ownerID: [String]? {
        get {
            return nil
        }
        set {
            return
        }
    }
    
    mutating func assignOwner(_ owner: String) {
        var array = ownerID ?? Array<String>()
        array.append(owner)
        ownerID = array
    }
    
    func update(_ model: Self) throws {
        
    }
}
