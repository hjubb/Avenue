//
//  ProductEvent.swift
//  App
//
//  Created by Szymon Lorenz on 3/1/20.
//

import Foundation
import FluentPostgreSQL
import Vapor

final class ListProduct: VaporPivot {
    static let leftIDKey: LeftIDKey = \.listID
    static let rightIDKey: RightIDKey = \.productID
    
    typealias Left = List
    typealias Right = Product
    
    var id: Int?
    var listID: Int
    var productID: Int
    
    init(_ left: List, _ right: Product) throws {
        listID = try left.requireID()
        productID = try right.requireID()
    }
}

extension ListProduct: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(ListProduct.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.productID)
            builder.field(for: \.listID)
            builder.reference(from: \.productID, to: \Product.id)
            builder.reference(from: \.listID, to: \List.id)
        }
    }
}
