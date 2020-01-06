/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

@testable import Avenue
import Vapor
import FluentPostgreSQL

public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    //Load Environment
    Environment.dotenv(filename: "\(try Environment.detect().name).env")
    // Register providers first
    try services.register(FluentPostgreSQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    //CRUD routes
    try MainController<Vendor>().boot(router: router)
    //Parent-Child relation routes
    try ChildController<Vendor, Event>(keypath: \Event.vendorID).boot(router: router)
    try ChildController<Vendor, Product>(keypath: \Product.vendorID).boot(router: router)
    try ChildController<Vendor, List>(keypath: \List.vendorID).boot(router: router)
    //Siblings routes
    try SiblingController<List, Product, ListProduct>(keypathLeft: ListProduct.leftIDKey, keypathRight: ListProduct.rightIDKey).boot(router: router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    let psqlConfig: PostgreSQLDatabaseConfig!
    if let url = Environment.get("PSQL_DATABASE_URL") {
        psqlConfig = PostgreSQLDatabaseConfig(url: url, transport: .unverifiedTLS)
    } else {
        psqlConfig = try PostgreSQLDatabaseConfig.default()
    }
    // Configure a PostgreSQL database
    let postgre = PostgreSQLDatabase(config: psqlConfig)
    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.enableLogging(on: .psql)
    databases.add(database: postgre, as: .psql)
    services.register(databases)
    // Configure migrations
    var migrations = MigrationConfig()
    //📋 Tables
    migrations.add(model: Vendor.self, database: .psql)
    migrations.add(model: Event.self, database: .psql)
    migrations.add(model: List.self, database: .psql)
    migrations.add(model: Product.self, database: .psql)
    //📋 Pivots tables
    migrations.add(model: ListProduct.self, database: .psql)
    
    
    services.register(migrations)

    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)

    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}

extension Application {
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        
        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }
        
        try configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        return app
    }
    
    static func reset() throws {
        let revertEnvironment = ["vapor", "revert", "--all", "-y"]
        try Application.testable(envArgs: revertEnvironment).asyncRun().wait()
        let migrateEnvironment = ["vapor", "migrate", "-y"]
        try Application.testable(envArgs: migrateEnvironment).asyncRun().wait()
    }
    
    func sendRequest<T>(to path: String,
                        method: HTTPMethod,
                        headers: HTTPHeaders = .init(),
                        body: T? = nil) throws -> Response where T: Content {
        let responder = try self.make(Responder.self)
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    func sendRequest(to path: String,
                     method: HTTPMethod,
                     headers: HTTPHeaders = .init()) throws -> Response {
        let emptyContent: EmptyContent? = nil
        return try sendRequest(to: path, method: method, headers: headers,
                               body: emptyContent)
    }
    
    func sendRequest<T>(to path: String,
                        method: HTTPMethod,
                        headers: HTTPHeaders, data: T) throws where T: Content {
        _ = try self.sendRequest(to: path, method: method, headers: headers, body: data)
    }
    
    func getResponse<C, T>(to path: String,
                           method: HTTPMethod = .GET,
                           headers: HTTPHeaders = .init(),
                           data: C? = nil,
                           decodeTo type: T.Type) throws -> T where C: Content, T: Decodable {
        let response = try self.sendRequest(to: path, method: method,
                                            headers: headers, body: data)
        return try response.content.decode(type).wait()
    }
    
    func getResponse<T>(to path: String,
                        method: HTTPMethod = .GET,
                        headers: HTTPHeaders = .init(),
                        decodeTo type: T.Type) throws -> T where T: Decodable {
        let emptyContent: EmptyContent? = nil
        return try self.getResponse(to: path, method: method, headers: headers,
                                    data: emptyContent, decodeTo: type)
    }
}

struct EmptyContent: Content {}
