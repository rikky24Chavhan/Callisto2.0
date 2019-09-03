//
//  Decodable+Extensions.swift
//  MealTrackingPilot
//
//  Created by Litteral, Maximilian on 10/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

enum CodingError: Error {
    case RuntimeError(String)
}

private func customDateEncodingStrategy(date: Date, encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    let dateString = DateFormatter.pilotStringFromDate(date)
    try container.encode(dateString)
}

extension JSONEncoder {
    class func CallistoJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(customDateEncodingStrategy)
        return encoder
    }
}

private func customDateDecodingStrategy(decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let dateStr = try container.decode(String.self)
    return try DateFormatter.pilotDateFromString(dateStr)
}

extension JSONDecoder {
    class func CallistoJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(customDateDecodingStrategy)
        return decoder
    }
}

extension Decodable {
    init(data: Data, keyPath: String? = nil) throws {
        let decoder = JSONDecoder.CallistoJSONDecoder()

        if let keyPath = keyPath {
            let topLevel = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            guard let nestedJson = (topLevel as AnyObject).value(forKeyPath: keyPath) else { throw CodingError.RuntimeError("Cannot decode data to object")  }
            let nestedData = try JSONSerialization.data(withJSONObject: nestedJson)
            let value = try decoder.decode(Self.self, from: nestedData)
            self = value
            return
        }
        let value = try decoder.decode(Self.self, from: data)
        self = value
    }
}

extension KeyedDecodingContainer {
    func decodeCallistoDate(forKey key: Key) throws -> Date {
        if let date = try? self.decode(Date.self, forKey: key) {
            return date
        } else if let dateString = try? self.decode(String.self, forKey: key) {
            return try DateFormatter.pilotDateFromString(dateString)
        }
        throw CodingError.RuntimeError("Cannot decode date")
    }

    func decodeMealOccasionsIfPresent(forKey key: Key) throws -> String? {
        guard let occasionsStrings = try self.decodeIfPresent([String].self, forKey: key) else { return nil }

        var occasionsString = occasionsStrings.joined(separator: "-").lowercased()
        let jsonPluralizedOccasions = MealOccasion.jsonPluralizedValues
        jsonPluralizedOccasions.forEach {
            occasionsString = occasionsString.replacingOccurrences(of: "\($0.rawValue)s", with: $0.rawValue)
        }

        return occasionsString
    }
}

extension Decodable {
    init(data: Data, keyPath: String? = nil, decoder: JSONDecoder) throws {
        if let keyPath = keyPath {
            let topLevel = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            guard let nestedJson = (topLevel as AnyObject).value(forKeyPath: keyPath) else { throw CodingError.RuntimeError("Cannot decode data to object")  }
            let nestedData = try JSONSerialization.data(withJSONObject: nestedJson)
            let value = try decoder.decode(Self.self, from: nestedData)
            self = value
            return
        }
        let value = try decoder.decode(Self.self, from: data)
        self = value
    }
}
