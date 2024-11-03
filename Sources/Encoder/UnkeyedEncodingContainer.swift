import Foundation

extension _BencodeEncoder {
    final class UnkeyedContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        private var storage = [BencodeEncodingContainer]()

        var count: Int {
            return storage.count
        }

        var nestedCodingPath: [CodingKey] {
            self.codingPath + [AnyCodingKey(intValue: self.count)!]
        }
    }
}

extension _BencodeEncoder.UnkeyedContainer: UnkeyedEncodingContainer {
    func encodeNil() throws {
        var container = self.nestedSingleValueContainer()
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        var container = self.nestedSingleValueContainer()
        try container.encode(value)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _BencodeEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        self.storage.append(container)
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _BencodeEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        self.storage.append(container)
        return container
    }

    func nestedSingleValueContainer() -> SingleValueEncodingContainer {
        let container = _BencodeEncoder.SingleValueContainer(codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        self.storage.append(container)
        return container
    }
    
    func superEncoder() -> Encoder {
        fatalError() // FIXME
    }
}

extension _BencodeEncoder.UnkeyedContainer: BencodeEncodingContainer {
    var data: Data {
        var data = Data([UInt8(ascii: "l")])

        for container in storage {
            data.append(contentsOf: container.data)
        }

        data.append(UInt8(ascii: "e"))
        return data
    }
}
