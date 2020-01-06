//
//  VendorControllerTests.swift
//  AppTests
//
//  Created by Szymon Lorenz on 25/11/19.
//

import Foundation
import Vapor
import XCTest
import FluentPostgreSQL
@testable import Avenue

extension Vendor {
    static func create(on connection: PostgreSQLConnection) throws -> Vendor {
        var vendor = Vendor(ownerID: nil)
        vendor.title = "Test Name"
        vendor.assignOwner("1234")
        return try vendor.save(on: connection).wait()
    }
}

class MainControllerTests: XCTestCase {
    static let allTests = [
        ("testGetVendor", testGetVendor),
        ("testCreateVendor", testCreateVendor),
        ("testUpdateVendor", testUpdateVendor),
        ("testDeleteVendor", testDeleteVendor),
    ]
    
    var app: Application!
    var conn: PostgreSQLConnection!
    
    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        conn.close()
        try? app.syncShutdownGracefully()
    }
        
    func testGetVendor() throws {
        let vendor = try Vendor.create(on: conn)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(Vendor.name.lowercased())/\(vendor.id!)", method: .GET, headers: headers)
        XCTAssertEqual(response.http.status.code, 200)
        
        let fetch = try response.content.syncDecode(Vendor.self)
        
        XCTAssertEqual(fetch.title, vendor.title)
        XCTAssertNotNil(fetch)
    }

    func testCreateVendor() throws {
        let vendor = Vendor(ownerID: nil)
        vendor.title = "hdska csakjch fhewg vdsjlhvgds"
        
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(Vendor.name.lowercased())", method: .POST, headers: headers, body: vendor)
        XCTAssertEqual(response.http.status.code, 200)
        
        let fetch = try response.content.syncDecode(Vendor.self)
        XCTAssertTrue(fetch.ownerID?.contains("1234") == true)
        XCTAssertEqual(fetch.title, vendor.title)
        XCTAssertNotNil(fetch)
    }
    
    func testUpdateVendor() throws {
        let created = try Vendor.create(on: conn)
        
        let vendor = Vendor(ownerID: nil)
        vendor.title = "hdska csakjch fhewg vdsjlhvgds"
        
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(Vendor.name.lowercased())/\(created.id!)", method: .PUT, headers: headers, body: vendor)
        XCTAssertEqual(response.http.status.code, 200)
        
        let fetch = try response.content.syncDecode(Vendor.self)
        XCTAssertTrue(fetch.ownerID?.contains("1234") == true)
        XCTAssertEqual(fetch.title, vendor.title)
        XCTAssertNotNil(fetch)
    }
    
    func testDeleteVendor() throws {
        let vendor = try Vendor.create(on: conn)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(Vendor.name.lowercased())/\(vendor.id!)", method: .DELETE, headers: headers)
        XCTAssertEqual(response.http.status.code, 204)
    }
}
