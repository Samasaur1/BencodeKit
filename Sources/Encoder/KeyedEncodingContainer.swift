import Foundation

extension _BencodeEncoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        private var storage = [String: BencodeEncodingContainer]()

        func nestedCodingPath(for key: CodingKey) -> [CodingKey] {
            self.codingPath + [key]
        }
    }
}

extension _BencodeEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        var container = self.nestedSingleValueContainer(for: key)
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        var container = self.nestedSingleValueContainer(for: key)
        try container.encode(value)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        if let container = self.storage[key.stringValue], let container = container as? _BencodeEncoder.UnkeyedContainer { return container }
        let container = _BencodeEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath(for: key), userInfo: self.userInfo)
        self.storage[key.stringValue] = container
        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        if let container = self.storage[key.stringValue], let container = container as? _BencodeEncoder.KeyedContainer<NestedKey> { return KeyedEncodingContainer(container) }
        let container = _BencodeEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath(for: key), userInfo: self.userInfo)
        self.storage[key.stringValue] = container
        return KeyedEncodingContainer(container)
    }

    func nestedSingleValueContainer(for key: Key) -> SingleValueEncodingContainer {
        let container = _BencodeEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(for: key), userInfo: self.userInfo)
        self.storage[key.stringValue] = container
        return container
    }
    
    func superEncoder() -> Encoder {
        fatalError()
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
}

extension _BencodeEncoder.KeyedContainer: BencodeEncodingContainer {
    var data: Data {
        var data = Data([UInt8(ascii: "d")])

        for (key, container) in self.storage.sorted(by: { first, second in first.key < second.key }) {
            let keyContainer = _BencodeEncoder.SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
            try! keyContainer.encode(key)
            data.append(keyContainer.data)
            data.append(container.data)
        }

        data.append(UInt8(ascii: "e"))
        return data
    }
}
