import Foundation

/**
 
 */
final public class BencodeEncoder {
    public init() {}

    public func encode(_ value: Encodable) throws -> Data {
        let encoder = _BencodeEncoder()
        switch value {
        case let x as Data:
            try x.encode(toBencode: encoder)
        default:
            try value.encode(to: encoder)
        }
        return encoder.data
    }
}

extension Data {
    func encode(toBencode encoder: _BencodeEncoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
}

final class _BencodeEncoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    fileprivate var container: BencodeEncodingContainer? {
        willSet {
            precondition(self.container == nil)
        }
    }

    var data: Data {
        container?.data ?? Data()
    }
}

extension _BencodeEncoder: Encoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()
        
        let container = KeyedContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()
        
        let container = UnkeyedContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        
        return container
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanCreateContainer()
        
        let container = SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        
        return container
    }
}

protocol BencodeEncodingContainer: AnyObject {
    var data: Data { get }
}
