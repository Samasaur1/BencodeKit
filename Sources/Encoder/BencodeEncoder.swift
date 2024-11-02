import Foundation

/**
 
 */
public class BencodeEncoder {
    func encode(_ value: Encodable) throws -> Data {
        let encoder = _BencodeEncoder()
        try value.encode(to: encoder)
        return encoder.data
    }

    enum Error: Swift.Error {
        case unsupportedType(type: Any.Type)
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

protocol BencodeEncodingContainer: class {
    var data: Data { get }
}
