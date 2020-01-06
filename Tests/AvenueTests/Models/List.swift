import Foundation
import FluentPostgreSQL
import Vapor

final class List: VaporSibling {
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    
    var id: Int?
    var vendorID: Vendor.ID!
    var createdAt: Date?
    var updatedAt: Date?
    var name: String?
    var description: String?
    
    init(id: Int? = nil, vendorID: Vendor.ID) {
        self.id = id
        self.vendorID = vendorID
    }
    
    func update(_ model: List) throws {
        name = model.name
        description = model.description
    }
    
    func isAttached<T>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<Bool> where T : PostgreSQLModel {
        return products.isAttached(model as! Product, on: conn)
    }
    
    func attach<T, P>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<P?> where T : PostgreSQLModel, P : VaporPivot {
        return products.attach(model as! Product, on: conn).map { pivot -> P? in
            return pivot as? P
        }
    }
    
    func detach<T>(_ model: T, on conn: DatabaseConnectable) -> EventLoopFuture<Void> where T : PostgreSQLModel {
        return products.detach(model as! Product, on: conn)
    }
}

extension List {
    var vendor: Parent<List, Vendor> {
        return parent(\.vendorID)
    }
    
    var products: Siblings<List, Product, ListProduct> {
        return siblings()
    }
}

extension List: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(List.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.vendorID)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.name)
            builder.field(for: \.description)
            
            builder.reference(from: \.vendorID, to: \Vendor.id, onDelete: .cascade)
            builder.unique(on: \.id)
        }
    }
}
