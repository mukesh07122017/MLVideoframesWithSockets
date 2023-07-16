//
//  EncodingHelper.swift
//  MLSocketSDK
//
//  Created by Mahi Sharma on 06/11/21.
//

import Foundation

internal class EncodingHelper {
    /**
    Gets the length of the size encoding.

    - Parameters:
        - buffer: The delimited, encoded message.
    */
    public static func getSizeOffset(buffer: [UInt8]) throws -> Int {
        var i: Int = 0
        var value: UInt64 = 0
        var shift: UInt64 = 0
        while true {
            let c = buffer[i]
            value |= UInt64(c & 0x7f) << shift
            if c & 0x80 == 0 {
                return i + 1;
            }
            shift += 7
            if shift > 63 {
                throw EncodingError.malformedProtobuf
            }
            i += 1
        }
    }

    public enum EncodingError : Error {
        case malformedProtobuf
    }
    
}

