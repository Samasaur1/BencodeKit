import Foundation

/**
 
 */
final public class BencodeDecoder {
    public init() {}

    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public var unknownKeyDecodingStrategy: UnknownKeyDecodingStrategy = BencodeDecoder.unknownKeyDecodingStrategyDefaultValue

    public enum UnknownKeyDecodingStrategy {
        case ignore
        case error
    }

    internal static var unknownKeyDecodingStrategyKey: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "unknownKeyDecodingStrategyKey")!
    }
    internal static let unknownKeyDecodingStrategyDefaultValue: UnknownKeyDecodingStrategy = .ignore

    public var leadingZeroDecodingStrategy: LeadingZeroDecodingStrategy = BencodeDecoder.leadingZeroDecodingStrategyDefaultValue

    public enum LeadingZeroDecodingStrategy {
        case ignore
        case error
    }

    internal static var leadingZeroDecodingStrategyKey: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "LeadingZeroDecodingStrategyKey")!
    }
    internal static let leadingZeroDecodingStrategyDefaultValue: LeadingZeroDecodingStrategy = .error

    public var leftoverDataDecodingStrategy: LeftoverDataDecodingStrategy = BencodeDecoder.leftoverDataDecodingStrategyDefaultValue

    public enum LeftoverDataDecodingStrategy {
        case ignore
        case error
    }

    internal static var leftoverDataDecodingStrategyKey: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "leftoverDataDecodingStrategy")!
    }
    internal static let leftoverDataDecodingStrategyDefaultValue: LeftoverDataDecodingStrategy = .error

    public var strictDictionaryOrderingDecodingStrategy: StrictDictionaryOrderingDecodingStrategy = BencodeDecoder.strictDictionaryOrderingDecodingStrategyDefaultValue

    public enum StrictDictionaryOrderingDecodingStrategy {
        case ignore
        case error
    }

    internal static var strictDictionaryOrderingDecodingStrategyKey: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "strictDictionaryOrderingDecodingStrategy")!
    }
    internal static let strictDictionaryOrderingDecodingStrategyDefaultValue: StrictDictionaryOrderingDecodingStrategy = .error
    
    internal var topLevel = true

    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        let decoder = _BencodeDecoder(data: data)
        decoder.userInfo = self.userInfo
        decoder.userInfo[BencodeDecoder.unknownKeyDecodingStrategyKey] = unknownKeyDecodingStrategy
        decoder.userInfo[BencodeDecoder.leadingZeroDecodingStrategyKey] = leadingZeroDecodingStrategy
        decoder.userInfo[BencodeDecoder.leftoverDataDecodingStrategyKey] = leftoverDataDecodingStrategy
        decoder.userInfo[BencodeDecoder.strictDictionaryOrderingDecodingStrategyKey] = strictDictionaryOrderingDecodingStrategy
        decoder.topLevel = self.topLevel

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
    
    internal var topLevel = true
    
    init(data: Data) {
        self.data = data
    }
}

extension _BencodeDecoder: Decoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    var leftoverDataDecodingStrategy: BencodeDecoder.LeftoverDataDecodingStrategy {
        return userInfo[BencodeDecoder.leftoverDataDecodingStrategyKey] as? BencodeDecoder.LeftoverDataDecodingStrategy ?? BencodeDecoder.leftoverDataDecodingStrategyDefaultValue
    }
        
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = try KeyedContainer<Key>(data: self.data, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        if self.topLevel {
            if container.index != container.data.endIndex {
                if self.leftoverDataDecodingStrategy == .error {
                    let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Extra data at end")
                    throw DecodingError.dataCorrupted(context)
                }
            }
        }

        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        assertCanCreateContainer()
        
        let container = try UnkeyedContainer(data: self.data, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        if self.topLevel {
            if container.index != container.data.endIndex {
                if self.leftoverDataDecodingStrategy == .error {
                    let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Extra data at end")
                    throw DecodingError.dataCorrupted(context)
                }
            }
        }

        return container
    }
    
    func singleValueContainer() -> SingleValueDecodingContainer {
        assertCanCreateContainer()
        
        let container = SingleValueContainer(data: self.data, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        // SingleValueContainers actually *are* lazy as God intended,
        // so the check is in _BencodeDecoder.SingleValueContainer instead
        
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
        guard self.index < self.data.endIndex else {
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
