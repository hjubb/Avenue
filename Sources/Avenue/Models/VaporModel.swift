import Foundation
import FluentPostgreSQL
import Vapor

public protocol VaporPivot: PostgreSQLPivot & ModifiablePivot & Content & Parameter {}

public protocol VaporSibling: VaporModel {
    func isAttached<T: PostgreSQLModel>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<Bool>
    func attach<T: PostgreSQLModel, P: VaporPivot>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<P?>
    func detach<T: PostgreSQLModel>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<Void>
}

public protocol VaporModel: PostgreSQLModel & Content & Parameter {
    var ownerID: [String]? { get set }
    func update(_ model: Self) throws
}

extension VaporModel {
    public var ownerID: [String]? {
        get {
            return nil
        }
        set {
            return
        }
    }
    
    public mutating func assignOwner(_ owner: String) {
        var array = ownerID ?? Array<String>()
        array.append(owner)
        ownerID = array
    }
    
    public func update(_ model: Self) throws {
        
    }
}
