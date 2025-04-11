import Foundation

extension _BencodeEncoder {
    final class SingleValueContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        private var storage = Data()
        private var canEncodeNewValue = true
        private func checkCanEncode(_ value: Any?) throws {
            guard self.canEncodeNewValue else {
                let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: "Attempt to encode value through single value container when previously value already encoded.")
                throw EncodingError.invalidValue(value as Any, context)
            }
        }
    }
}

extension _BencodeEncoder.SingleValueContainer: SingleValueEncodingContainer {
    func encodeNil() throws {
        // no-op
    }
    
    func encode(_ value: Bool) throws {
        let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot encode Bool")
        throw EncodingError.invalidValue(value, context)
    }
    
    func encode(_ value: String) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("\(value.utf8.count):\(value)".utf8))
    }
    
    func encode(_ value: Double) throws {
        let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot encode Double")
        throw EncodingError.invalidValue(value, context)
    }
    
    func encode(_ value: Float) throws {
        let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot encode Float")
        throw EncodingError.invalidValue(value, context)
    }
    
    func encode(_ value: Int) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: Int8) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: Int16) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: Int32) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: Int64) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: UInt) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: UInt8) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: UInt16) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: UInt32) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }
    
    func encode(_ value: UInt64) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("i\(value)e".utf8))
    }

    func encodeData(_ value: Data) throws {
        try checkCanEncode(value)
        defer { self.canEncodeNewValue = false }
        storage.append(Data("\(value.count):".utf8))
        storage.append(value)
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        switch value {
        case let data as Data:
            try self.encodeData(data)
        default:
            let encoder = _BencodeEncoder()
            try value.encode(to: encoder)
            self.storage.append(encoder.data)
        }
    }
}

extension _BencodeEncoder.SingleValueContainer: BencodeEncodingContainer {
    var data: Data {
        self.storage
    }
}
