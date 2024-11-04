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
        let startIndex = self.index
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("string length bytes were not valid ASCII")
        }
        guard let length = Int(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "String length not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: ":") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "String length must be followed by a colon")
        }
        let data = try self.read(length)
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
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit || x == UInt8(ascii: "-") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit or a minus sign")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = Int(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit || x == UInt8(ascii: "-") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit or a minus sign")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = Int8(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit || x == UInt8(ascii: "-") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit or a minus sign")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = Int16(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit || x == UInt8(ascii: "-") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit or a minus sign")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = Int32(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit || x == UInt8(ascii: "-") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit or a minus sign")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = Int64(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = UInt(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = UInt8(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = UInt16(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = UInt32(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard try self.readByte() == UInt8(ascii: "i") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must begin with i")
        }
        let startIndex = self.index
        guard let x = self.peek(), x.isDigit else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must start with a digit")
        }
        self.index = self.index.advanced(by: 1)
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("int string bytes were not valid ASCII")
        }
        guard let val = UInt64(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int string not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: "e") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
        }
        return val
    }

    func decodeData(_ type: Data.Type) throws -> Data {
        let startIndex = self.index
        while let x = self.peek(), x.isDigit {
            self.index = self.index.advanced(by: 1)
        }
        guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
            fatalError("string length bytes were not valid ASCII")
        }
        guard let length = Int(s) else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Data length not convertible to int")
        }
        guard try self.readByte() == UInt8(ascii: ":") else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Data length must be followed by a colon")
        }
        return try self.read(length)
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        switch type {
        case is Data.Type:
            return try decodeData(Data.self) as! T
        default:
            let decoder = _BencodeDecoder(data: self.data)
            let value = try T(from: decoder)
            if let nextIndex = decoder.container?.index {
                self.index = nextIndex
            }
            return value
        }
    }
}

extension _BencodeDecoder.SingleValueContainer: BencodeDecodingContainer {}

extension UInt8 {
    var isDigit: Bool {
        self >= 48 && self <= 57
    }
}
