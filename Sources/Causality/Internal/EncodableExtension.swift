//
//  EncodableExtension.swift
//  
//
//  Created by Danny Sung on 10/03/2020.
//

import Foundation

internal extension Encodable {
    var hashOfCodableValues: Int {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try! encoder.encode(self)
        var hasher = Hasher()
        data.withUnsafeBytes { (bytes) in
            hasher.combine(bytes: bytes)
        }
        hasher.combine(data)
        let hashValue = hasher.finalize()
        return hashValue
    }

}
