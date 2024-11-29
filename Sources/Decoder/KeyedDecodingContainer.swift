import Foundation

extension _BencodeDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
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

        func nestedCodingPath(for key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }

        var count: Int? {
            self.nestedContainers.count
        }

        private var _nestedContainers: [String: BencodeDecodingContainer]? = nil
        var nestedContainers: [String: BencodeDecodingContainer] {
            _nestedContainers!
        }

        private func parseNestedContainers() throws -> [String: BencodeDecodingContainer] {
            guard let byte = try? self.readByte(), byte == UInt8(ascii: "d") else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Keyed container must begin with a d")
                throw DecodingError.dataCorrupted(context)
            }

            var containers: [String: BencodeDecodingContainer] = [:]

            let unkeyedContainer = try UnkeyedContainer(data: [UInt8(ascii: "l")] + self.data.suffix(from: self.index), codingPath: self.codingPath, userInfo: self.userInfo)

            var it = unkeyedContainer.nestedContainers.makeIterator()
            while let keyContainer = it.next() {
                guard let keyContainer = keyContainer as? _BencodeDecoder.SingleValueContainer else {
                    let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Keyed container has key that is not SingleValueContainer")
                    throw DecodingError.dataCorrupted(context)
                }
                guard let valueContainer = it.next() else {
                    let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Keyed container has one more key than value")
                    throw DecodingError.dataCorrupted(context)
                }
                let key = try keyContainer.decode(String.self)

                let codingKey: any CodingKey
                switch unknownKeyDecodingStrategy {
                case .ignore:
                    // AnyCodingKey is guaranteed to always succeed, even though the initializer is marked failable,
                    codingKey = AnyCodingKey(stringValue: key)!
                case .error:
                    // Key will fail if the decoded key is not a defined key in the object
                    guard let _key = Key(stringValue: key) else {
                        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unknown key '\(key)' found in object")
                        throw DecodingError.dataCorrupted(context)
                    }
                    codingKey = _key
                }
                valueContainer.codingPath += [codingKey]

                containers[key] = valueContainer
            }

            // Incredibly cursed, but without doing this all nested dictionaries break
            // I believe this is because the data we pass to the unkeyed container is not
            //   purely a suffix (subdata) of this keyed container's data, and is instead
            //   a new data instance, which (presumably) causes the indexing to be different.
            self.index = self.data.endIndex.advanced(by: unkeyedContainer.data.endIndex.distance(to: unkeyedContainer.index))

            return containers
        }

        func checkCanDecode(for key: Key) throws {
            guard self.contains(key) else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "key not found: \(key)")
                throw DecodingError.keyNotFound(key, context)
            }
        }

        var unknownKeyDecodingStrategy: BencodeDecoder.UnknownKeyDecodingStrategy {
            return userInfo[BencodeDecoder.unknownKeyDecodingStrategyKey] as? BencodeDecoder.UnknownKeyDecodingStrategy ?? BencodeDecoder.unknownKeyDecodingStrategyDefaultValue
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
        return !self.contains(key)
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
        
        guard let keyedContainer = self.nestedContainers[key.stringValue] else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }
        let container = try _BencodeDecoder.KeyedContainer<NestedKey>(data: keyedContainer.data, codingPath: keyedContainer.codingPath, userInfo: keyedContainer.userInfo)
        
        return KeyedDecodingContainer(container)
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
