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
    
    static func applyQuery(_ req: Request, _ query: QueryBuilder<PostgreSQLDatabase, Self>) -> QueryBuilder<PostgreSQLDatabase, Self> {
        var query = query
        if let queryRequest = try? req.query.decode(Query.self) {
            queryRequest.where?.forEach {
                let op = PostgreSQLBinaryOperator(stringLiteral: $0.value.operator)
                let tableIdentifierString = PostgreSQLTableIdentifier(stringLiteral: Self.sqlTableIdentifierString)
                query = query.filter(PostgreSQLColumnIdentifier.column(tableIdentifierString, PostgreSQLIdentifier($0.value.key)), op, $0.value.value)
            }
            if let pagination = queryRequest.offset {
                let startIndex = pagination.index ?? 0
                let length = pagination.length ?? 50
                let endIndex = startIndex + length
                query = query.range(startIndex ..< endIndex)
            }
            if let order = queryRequest.order {
                let tableIdentifierString = PostgreSQLTableIdentifier(stringLiteral: Self.sqlTableIdentifierString)
                query = query.sort(PostgreSQLOrderBy.orderBy(.column(PostgreSQLColumnIdentifier.column(tableIdentifierString, PostgreSQLIdentifier(order.key))), order.descending ? .descending : .ascending))
            }
        }
        return query
    }
}
