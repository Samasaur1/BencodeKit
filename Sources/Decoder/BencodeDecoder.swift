import Foundation

/**
 
 */
final public class BencodeDecoder {
    public init() {}

    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        let decoder = _BencodeDecoder(data: data)
        switch type {
        case is Data.Type:
            return try Data(bencodeDecoder: decoder) as! T
        default:
            return try T(from: decoder)
        }
    }
}

extension Data {
    init(bencodeDecoder decoder: _BencodeDecoder) throws {
        self = try decoder.singleValueContainer().decode(Self.self)
    }
}

final class _BencodeDecoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var container: BencodeDecodingContainer?
    fileprivate var data: Data
    
    init(data: Data) {
        self.data = data
    }
}

extension _BencodeDecoder: Decoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }
        
    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(data: self.data, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedDecodingContainer {
        assertCanCreateContainer()
        
        let container = UnkeyedContainer(data: self.data, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }
    
    func singleValueContainer() -> SingleValueDecodingContainer {
        assertCanCreateContainer()
        
        let container = SingleValueContainer(data: self.data, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        
        return container
    }
}

protocol BencodeDecodingContainer: AnyObject {
    var codingPath: [CodingKey] { get set }
    
    var userInfo: [CodingUserInfoKey : Any] { get }

    var data: Data { get set }
    var index: Data.Index { get set }
}
extension BencodeDecodingContainer {
    func peek() -> UInt8? {
        guard self.index <= self.data.endIndex else {
            return nil
        }
        return self.data[self.index]
    }

    func readByte() throws -> UInt8 {
        return try read(1).first!
    }
    
    func read(_ length: Int) throws -> Data {
        let nextIndex = self.index.advanced(by: length)
        guard nextIndex <= self.data.endIndex else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unexpected end of data")
            throw DecodingError.dataCorrupted(context)
        }
        defer { self.index = nextIndex }
        
        return self.data.subdata(in: self.index..<nextIndex)
    }
}
