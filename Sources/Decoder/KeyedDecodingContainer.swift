import Foundation

extension _BencodeDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
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

        func nestedCodingPath(for key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }

        var count: Int? {
            self.nestedContainers.count
        }

        lazy var nestedContainers: [String: BencodeDecodingContainer] = {
            guard let byte = try? self.readByte(), byte == UInt8(ascii: "d") else {
                try! {
                    let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Keyed container must begin with a d")
                    throw DecodingError.dataCorrupted(context)
                }()
                return [:]
            }

            var containers: [String: BencodeDecodingContainer] = [:]

            let unkeyedContainer = UnkeyedContainer(data: [UInt8(ascii: "l")] + self.data.suffix(self.index), codingPath: self.codingPath, userInfo: self.userInfo)

            var it = unkeyedContainer.nestedContainers.makeIterator()
            while let keyContainer = it.next() as? _BencodeDecoder.SingleValueContainer,
                let valueContainer = it.next() {
                let key = try! keyContainer.decode(String.self)
                valueContainer.codingPath += [AnyCodingKey(stringValue: key)!]
                containers[key] = valueContainer
            }

            self.index = unkeyedContainer.index

            return nestedContainers
        }()

        func checkCanDecode(for key: Key) throws {
            guard self.contains(key) else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "key not found: \(key)")
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
}

extension _BencodeDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return self.nestedContainers.keys.compactMap(Key.init(stringValue:))
    }
    
    func contains(_ key: Key) -> Bool {
        return self.nestedContainers.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        // no-op
        fatalError()
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        try checkCanDecode(for: key)

        guard let container = self.nestedContainers[key.stringValue] else {
            let context = DecodingError.Context(codingPath: self.nestedCodingPath(for: key), debugDescription: "missing key")
            throw DecodingError.keyNotFound(key, context)
        }

        let decoder = BencodeDecoder()
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }
    
 
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try checkCanDecode(for: key)

        guard let unkeyedContainer = self.nestedContainers[key.stringValue] as? _BencodeDecoder.UnkeyedContainer else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }

        return unkeyedContainer
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        try checkCanDecode(for: key)
        
        guard let keyedContainer = self.nestedContainers[key.stringValue] as? _BencodeDecoder.KeyedContainer<NestedKey> else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }
        
        return KeyedDecodingContainer(keyedContainer)
    }
    
    func superDecoder() throws -> Decoder {
        return _BencodeDecoder(data: self.data)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        let decoder = _BencodeDecoder(data: self.data)
        decoder.codingPath = [key]

        return decoder
    }
}

extension _BencodeDecoder.KeyedContainer: BencodeDecodingContainer {}
