import Foundation

extension _BencodeDecoder {
    final class SingleValueContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        var data: Data
        var index: Data.Index

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
        }

        var leadingZeroDecodingStrategy: BencodeDecoder.LeadingZeroDecodingStrategy {
            return userInfo[BencodeDecoder.leadingZeroDecodingStrategyKey] as? BencodeDecoder.LeadingZeroDecodingStrategy ?? BencodeDecoder.leadingZeroDecodingStrategyDefaultValue
        }
    }
}

extension _BencodeDecoder.SingleValueContainer: SingleValueDecodingContainer {    
    func decodeNil() -> Bool {
        // noop
        fatalError()
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        fatalError()
    }
    
    func decode(_ type: String.Type) throws -> String {
        let data = try decodeBytes(for: type)
        guard let str = String(bytes: data, encoding: .utf8) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "String was not valid UTF-8")
        }
        return str
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        fatalError()
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        fatalError()
    }

    func decode(_ type: Int.Type) throws -> Int {
        try decodeIntCore(for: type)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try decodeIntCore(for: type)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try decodeIntCore(for: type)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try decodeIntCore(for: type)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try decodeIntCore(for: type)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try decodeIntCore(for: type)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try decodeIntCore(for: type)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try decodeIntCore(for: type)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try decodeIntCore(for: type)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try decodeIntCore(for: type)
    }

    func decodeData(_ type: Data.Type) throws -> Data {
        return try decodeBytes(for: type)
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let res: T
        
        switch type {
        case is Data.Type:
            res = try decodeData(Data.self) as! T
        default:
            let decoder = _BencodeDecoder(data: self.data)
            decoder.userInfo = self.userInfo
            let value = try T(from: decoder)
            if let nextIndex = decoder.container?.index {
                self.index = nextIndex
            }
            res = value
        }
        
        if self.index != self.data.endIndex {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Extra data at end")
            throw DecodingError.dataCorrupted(context)
        }
        
        return res
    }

    private func decodeBytes(for userFacingType: Any.Type) throws -> Data {
        let startIndex = self.index
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("\(userFacingType) length bytes were not valid ASCII")
        }
        guard let length = Int(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) length not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: ":") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) length must be followed by a colon")
        }
        let res = try self.read(length)
        
        if self.index != self.data.endIndex {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Extra data at end")
            throw DecodingError.dataCorrupted(context)
        }
        
        return res
    }
    
    private func decodeIntCore<T: FixedWidthInteger>(for userFacingType: T.Type) throws -> T {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit || x == UInt8(ascii: "-") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) must start with a digit or a minus sign")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("\(userFacingType) string bytes were not valid ASCII")
        }
        if s.count == 1 {
            if s == "-" {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) string was '-'")
            }
        } else {
            // s.count > 1
            var it = s.makeIterator()
            switch it.next()! {
            case "0":
                if self.leadingZeroDecodingStrategy == .error {
                    throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) string had leading zero")
                }
            case "-":
                if it.next()! == "0" {
                    if s.count == 2 {
                        // the whole string is i-0e, which is always invalid
                        throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) string was -0")
                    } else {
                        // the string is a negative number with a leading zero
                        if self.leadingZeroDecodingStrategy == .error {
                            throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) string had (negative) leading zero")
                        }
                    }
                }
            default:
                break
            }
        }
        guard let val = T(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "\(userFacingType) must end with an e")
        }
        
        if self.index != self.data.endIndex {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Extra data at end")
            throw DecodingError.dataCorrupted(context)
        }
        
        return val
    }
}

extension _BencodeDecoder.SingleValueContainer: BencodeDecodingContainer {}

extension UInt8 {
    var isDigit: Bool {
        self >= 48 && self <= 57
    }
}
