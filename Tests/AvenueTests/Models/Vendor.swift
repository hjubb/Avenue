import Foundation
import FluentPostgreSQL
import Vapor
@testable import Avenue

final class Vendor: VaporModel {
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    
    var id: Int?
    var ownerID: [String]?
    var createdAt: Date?
    var updatedAt: Date?
    var title: String?
    var description: String?
    
    init(id: Int? = nil, ownerID: [String]?) {
        self.id = id
        self.ownerID = ownerID
    }
    
    func update(_ model: Vendor) throws {
        title = model.title
        description = model.description
    }
}

extension Vendor {
    var events: Children<Vendor, Event> {
        return children(\Event.vendorID)
    }
    
    var lists: Children<Vendor, List> {
        return children(\List.vendorID)
    }
    
    var products: Children<Vendor, Product> {
        return children(\Product.vendorID)
    }
}

extension Vendor: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(Vendor.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.ownerID)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.title)
            builder.field(for: \.description)
            
            builder.unique(on: \.id)
        }
    }
}
