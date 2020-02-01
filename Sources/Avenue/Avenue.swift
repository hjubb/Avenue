import Foundation
import Vapor

public struct Filter: Content {
    var key: String
    var value: AnyValue
    var `operator`: String
}

public struct Offset: Content {
    public var index: Int?
    public var length: Int?
}

public struct Order: Content {
    var key: String
    var descending: Bool
}

public struct Query: Content {
    public var order: Order?
    public var offset: Offset?
    public var `where`: [Int : Filter]?
}

public var decoderJSON: JSONDecoder = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(formatter)
    return decoder
}()
