import Foundation

extension _BencodeDecoder {
    final class UnkeyedContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        var data: Data
        var index: Data.Index

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) throws {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex

            self._nestedContainers = try parseNestedContainers()
        }

        var nestedCodingPath: [CodingKey] {
            self.codingPath + [AnyCodingKey(intValue: self.currentIndex)!]
        }

        var count: Int? {
            self.nestedContainers.count
        }
        var currentIndex = 0

        private var _nestedContainers: [BencodeDecodingContainer]? = nil
        var nestedContainers: [BencodeDecodingContainer] {
            _nestedContainers!
        }

        private func parseNestedContainers() throws -> [BencodeDecodingContainer] {
            guard let byte = try? self.readByte(), byte == UInt8(ascii: "l") else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unkeyed container must begin with an l")
            }

            var containers: [BencodeDecodingContainer] = []

            while let nextByte = self.peek() {
                if nextByte == UInt8(ascii: "e") {
                    self.currentIndex = 0
                    self.index = self.index.advanced(by: 1) // consume the 'e'
                    return containers
                }
                containers.append(try self.decodeContainer())
            }

            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unkeyed container must end with an e")
        }

        var isAtEnd: Bool {
            guard let count else {
                return true
            }
            return self.currentIndex >= count
        }

        func checkCanDecode() throws {
            guard !self.isAtEnd else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
            }
        }
    }
}

extension _BencodeDecoder.UnkeyedContainer: UnkeyedDecodingContainer {
    func decodeNil() throws -> Bool {
        // no-op
        fatalError()
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try checkCanDecode()
        defer { self.currentIndex += 1 }

        let container = self.nestedContainers[self.currentIndex]
        let decoder = BencodeDecoder()
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        // // guard try self.readByte() == UInt8(ascii: "l") else {
        // // }
        // let container = _BencodeDecoder.UnkeyedContainer(data: self.data.suffix(from: self.index), codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        // self.index = container.index
        //
        // return container
        try checkCanDecode()
        defer { self.currentIndex += 1 }

        guard let container = self.nestedContainers[self.currentIndex] as? _BencodeDecoder.UnkeyedContainer else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Cannot convert to unkeyed container")
        }

        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        try checkCanDecode()
        defer { self.currentIndex += 1 }

        guard let container = self.nestedContainers[self.currentIndex] as? _BencodeDecoder.KeyedContainer<NestedKey> else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Cannot convert to keyed container")
        }

        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        return _BencodeDecoder(data: self.data)
    }
}

extension _BencodeDecoder.UnkeyedContainer: BencodeDecodingContainer {
    func decodeContainer() throws -> BencodeDecodingContainer {
//        try checkCanDecode() // FIXME: is this necessary?
        defer { self.currentIndex += 1 }

        let startIndex = self.index

        let nextByte = try self.readByte()
        switch nextByte {
        case let x where x.isDigit:
            while let x = self.peek(), x.isDigit {
                self.index = self.index.advanced(by: 1)
            }
            guard let s = String(bytes: self.data[startIndex..<self.index], encoding: .ascii) else {
                fatalError("string length bytes were not valid ASCII")
            }
            guard let length = Int(s) else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "String length not convertible to int")
            }

            let range: Range<Data.Index> = startIndex..<(self.index + 1 + length)
            self.index = range.upperBound

            return _BencodeDecoder.SingleValueContainer(data: self.data[range], codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        case UInt8(ascii: "i"):
            while let x = self.peek(), x.isDigit || x == UInt8(ascii: "-") {
                self.index = self.index.advanced(by: 1)
            }
            let endByte = try self.readByte()
            guard endByte == UInt8(ascii: "e") else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Int must end with an e")
            }

            return _BencodeDecoder.SingleValueContainer(data: self.data[startIndex..<self.index], codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        case UInt8(ascii: "l"):
            let container = try _BencodeDecoder.UnkeyedContainer(data: self.data.suffix(from: startIndex), codingPath: self.nestedCodingPath, userInfo: self.userInfo)
            self.index = container.index

            return container
        case UInt8(ascii: "d"):
            let container = try _BencodeDecoder.KeyedContainer<AnyCodingKey>(data: self.data.suffix(from: startIndex), codingPath: self.nestedCodingPath, userInfo: self.userInfo)
            self.index = container.index

            return container
        case UInt8(ascii: "e"):
            fatalError()
        default:
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "invalid")
        }
    }
}
