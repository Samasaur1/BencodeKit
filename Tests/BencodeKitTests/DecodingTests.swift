import Testing
import Foundation
@testable import BencodeKit

@Suite
struct DecodingTests {
    @Suite
    struct IntDecodingTests {
        @Test("Decode positive integer", arguments: 1...100)
        func decodePositiveInt(n: Int) async throws {
            let data = try #require("i\(n)e".data(using: .utf8)) // utf8 == ascii in this case
            let i = try BencodeDecoder().decode(Int.self, from: data)
            #expect(i == n)
        }

        @Test func decodePositiveZero() async throws {
            let n = 0
            let data = try #require("i0e".data(using: .utf8)) // utf8 == ascii in this case
            let i = try BencodeDecoder().decode(Int.self, from: data)
            #expect(i == n)
        }

        @Test(.disabled())
        func decodeNegativeZero() async throws {
            let data = try #require("i-0e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: (any Error).self) {
                try BencodeDecoder().decode(Int.self, from: data)
            }
        }

        @Test("Decode negative integer", arguments: -100 ... -1)
        func decodeNegativeInt(n: Int) async throws {
            let data = try #require("i\(n)e".data(using: .utf8)) // utf8 == ascii in this case
            let i = try BencodeDecoder().decode(Int.self, from: data)
            #expect(i == n)
        }
    }

    @Suite
    struct StringDecodingTests {
        @Test
        func emptyString() async throws {
            let data = try #require("0:".data(using: .utf8)) // utf8 == ascii in this case
            let s = try BencodeDecoder().decode(String.self, from: data)
            #expect(s == "")
        }

        @Test(arguments: ["Hello, world!"])
        func decodeString(realString: String) async throws {
            do {
                let data = try #require("\(realString.count):\(realString)".data(using: .ascii))
                let s = try BencodeDecoder().decode(String.self, from: data)
                #expect(s == realString)
            }
            let data = try #require("\(realString.count):\(realString)".data(using: .utf8))
            let s = try BencodeDecoder().decode(String.self, from: data)
            #expect(s == realString)
        }

        // These are DIFFERENT.
        // The first uses the Unicode character "LATIN SMALL LETTER U WITH DIAERESIS"
        // This is represented in UTF-8 by 0xC3 0xBC
        // The second uses the Unicode character "LATIN SMALL LETTER U" followed by the Unicode character "COMBINING DIAERESIS"
        // This is represented in UTF-8 by 0x75 0xCC 0x88
        // As such, their length (in bytes) varies
        @Test(arguments: ["ü", "ü"])
        func decodeMultiByteCharacter(realString: String) async throws {
            let trueStringData = try #require(realString.data(using: .utf8))
            let countData = try #require("\(trueStringData.count):".data(using: .ascii))
            let data = countData + trueStringData
            let s = try BencodeDecoder().decode(String.self, from: data)
            #expect(s == realString)
        }
    }

    @Suite
    struct DataDecodingTests {
        @Test
        func emptyData() async throws {
            let data = try #require("0:".data(using: .utf8)) // utf8 == ascii in this case
            let s = try BencodeDecoder().decode(Data.self, from: data)
            #expect(s == Data())
        }

        struct DataWrapper: Decodable {
            let d: Data
        }
        @Test
        func wrappedEmptyData() async throws {
            let data = try #require("d1:d0:e".data(using: .utf8)) // utf8 == ascii in this case
            let s = try BencodeDecoder().decode(DataWrapper.self, from: data)
            #expect(s.d == Data())
        }
    }

    @Suite
    struct ArrayDecodingTests {
        @Test
        func emptyArray() async throws {
            let data = try #require("le".data(using: .utf8)) // utf8 == ascii in this case
            let a = try BencodeDecoder().decode([Int].self, from: data)
            #expect(a == [])
        }

        @Test(arguments: [1, 2, 10])
        func nElementIntArray(count: Int) async throws {
            let data = try #require("l\(String(repeating: "i0e", count: count))e".data(using: .utf8)) // utf8 == ascii in this case
            let arr = try BencodeDecoder().decode([Int].self, from: data)
            let correctArray = [Int](repeating: 0, count: count)
            #expect(arr == correctArray)
        }
        
        @Test(arguments: [1, 2, 10])
        func arrayOfEmptyArrays(count: Int) async throws {
            let data = try #require("l\(String(repeating: "le", count: count))e".data(using: .utf8)) // utf8 == ascii in this case
            let arr = try BencodeDecoder().decode([[Int]].self, from: data)
            let correctArray = [[Int]](repeating: [], count: count)
            #expect(arr == correctArray)
        }
        
        @Test(arguments: [1, 2, 10])
        func arrayOfEmptyDictionaries(count: Int) async throws {
            let data = try #require("l\(String(repeating: "de", count: count))e".data(using: .utf8)) // utf8 == ascii in this case
            let arr = try BencodeDecoder().decode([[String: Int]].self, from: data)
            let correctArray = [[String: Int]](repeating: [:], count: count)
            #expect(arr == correctArray)
        }
        
        @Test(arguments: [1, 2, 10], [1, 2, 10])
        func arrayOfArrays(innerCount: Int, outerCount: Int) async throws {
            let innerStr = String(repeating: "i0e", count: innerCount)
            let data = try #require("l\(String(repeating: "l\(innerStr)e", count: outerCount))e".data(using: .utf8)) // utf8 == ascii in this case
            let arr = try BencodeDecoder().decode([[Int]].self, from: data)
            let correctArray = [[Int]](repeating: [Int](repeating: 0, count: innerCount), count: outerCount)
            #expect(arr == correctArray)
        }
        
        @Test(arguments: [1, 2, 10])
        func arrayOfDictionaries(outerCount: Int) async throws {
            let innerStr = "d3:onei1e5:threei3e3:twoi2ee"
            let data = try #require("l\(String(repeating: innerStr, count: outerCount))e".data(using: .utf8)) // utf8 == ascii in this case
            let arr = try BencodeDecoder().decode([[String: Int]].self, from: data)
            let correctArray = [[String: Int]](repeating: ["one": 1, "two": 2, "three": 3], count: outerCount)
            #expect(arr == correctArray)
        }
    }

    @Suite
    struct DictionaryDecodingTests {
        @Test
        func emptyDictionary() async throws {
            let data = try #require("de".data(using: .utf8)) // utf8 == ascii in this case
            let dict = try BencodeDecoder().decode([String: Int].self, from: data)
            #expect(dict == [:])
        }
        
        @Test
        func dictionaryToInt() async throws {
            let data = try #require("d3:onei1e5:threei3e3:twoi2ee".data(using: .utf8)) // utf8 == ascii in this case
            let dict = try BencodeDecoder().decode([String: Int].self, from: data)
            #expect(dict == ["one": 1, "two": 2, "three": 3])
        }
        
        @Test
        func dictionaryOfEmptyArrays() async throws {
            let data = try #require("d3:onele5:threele3:twolee".data(using: .utf8)) // utf8 == ascii in this case
            let dict = try BencodeDecoder().decode([String: [Int]].self, from: data)
            #expect(dict == ["one": [], "two": [], "three": []])
        }
        
        @Test
        func dictionaryOfEmptyDictionaries() async throws {
            let data = try #require("d3:onede5:threede3:twodee".data(using: .utf8)) // utf8 == ascii in this case
            let dict = try BencodeDecoder().decode([String: [String: Int]].self, from: data)
            #expect(dict == ["one": [:], "two": [:], "three": [:]])
        }
        
        @Test
        func dictionaryOfArrays() async throws {
            let data = try #require("d3:oneli1ee5:threeli4ei5ei6ee3:twoli2ei3eee".data(using: .utf8)) // utf8 == ascii in this case
            let dict = try BencodeDecoder().decode([String: [Int]].self, from: data)
            #expect(dict == ["one": [1], "two": [2, 3], "three": [4, 5, 6]])
        }
        
        @Test
        func dictionaryOfDictionaries() async throws {
            let innerStr = "d3:onei1e5:threei3e3:twoi2ee"
            let innerDict = ["one": 1, "two": 2, "three": 3]
            let data = try #require("d5:first\(innerStr)6:second\(innerStr)5:third\(innerStr)e".data(using: .utf8)) // utf8 == ascii in this case
            let dict = try BencodeDecoder().decode([String: [String: Int]].self, from: data)
            let correctDict = ["first": innerDict, "second": innerDict, "third": innerDict]
            #expect(dict == correctDict)
        }
    }
    
    @Suite
    struct ObjectDecodingTests {
        struct EmptyObject: Codable, Equatable {}
        @Test
        func emptyObject() async throws {
            let data = try #require("de".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(EmptyObject.self, from: data)
            #expect(obj == EmptyObject())
        }
        
        struct SingleIntObject: Codable, Equatable { let value: Int }
        @Test
        func singleIntObject() async throws {
            let data = try #require("d5:valuei0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(SingleIntObject.self, from: data)
            #expect(obj == SingleIntObject(value: 0))
        }
        
        struct SingleStringObject: Codable, Equatable { let value: String }
        @Test
        func singleStringObject() async throws {
            let data = try #require("d5:value1:0e".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(SingleStringObject.self, from: data)
            #expect(obj == SingleStringObject(value: "0"))
        }
        
        struct DoubleIntObject: Codable, Equatable { let v1: Int; let v2: Int }
        @Test
        func doubleIntObject() async throws {
            let data = try #require("d2:v1i3e2:v2i4ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(DoubleIntObject.self, from: data)
            #expect(obj == DoubleIntObject(v1: 3, v2: 4))
        }
        
        struct DoubleStringObject: Codable, Equatable { let v1: String; let v2: String }
        @Test
        func doubleStringObject() async throws {
            let data = try #require("d2:v11:32:v21:4e".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(DoubleStringObject.self, from: data)
            #expect(obj == DoubleStringObject(v1: "3", v2: "4"))
        }
        
        struct IntAndStringObject: Codable, Equatable { let ival: Int; let sval: String }
        @Test
        func intAndStringObject() async throws {
            let data = try #require("d4:ivali0e4:sval1:0e".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(IntAndStringObject.self, from: data)
            #expect(obj == IntAndStringObject(ival: 0, sval: "0"))
        }
        
        struct NestedObject: Codable, Equatable { let obj: SingleIntObject }
        @Test
        func nestedObject() async throws {
            let data = try #require("d3:obj\("d5:valuei0ee")e".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(NestedObject.self, from: data)
            #expect(obj == NestedObject(obj: SingleIntObject(value: 0)))
        }
        
        struct NestedNestedObject: Codable, Equatable { let outer: NestedObject }
        @Test
        func nestedNestedObject() async throws {
            let data = try #require("d5:outer\("d3:obj\("d5:valuei0ee")e")e".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(NestedNestedObject.self, from: data)
            #expect(obj == NestedNestedObject(outer: NestedObject(obj: SingleIntObject(value: 0))))
        }

        @Test
        func objectWithExtraKey() async throws {
            let data = try #require("d5:valuei0e5:otheri1ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(SingleIntObject.self, from: data)
            #expect(obj == SingleIntObject(value: 0))
        }

        @Test
        func objectWithMissingKey() async throws {
            let data = try #require("de".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                try BencodeDecoder().decode(SingleIntObject.self, from: data)
            }
        }

        @Test
        func objectWithValueOfIncorrectType() async throws {
            let data = try #require("d5:value5:valuee".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                try BencodeDecoder().decode(SingleIntObject.self, from: data)
            }
        }
    }

    @Suite
    struct NilTests {
        struct ObjectWithOptionalProperty: Codable, Equatable { let required: Int; let optional: Int? }
        @Test
        func objectWithNilOptionalProperty() async throws {
            let data = try #require("d8:requiredi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithOptionalProperty.self, from: data)
            #expect(obj == ObjectWithOptionalProperty(required: 0, optional: nil))
        }

        @Test
        func objectWithNonNilOptionalProperty() async throws {
            let data = try #require("d8:optionali1e8:requiredi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithOptionalProperty.self, from: data)
            #expect(obj == ObjectWithOptionalProperty(required: 0, optional: 1))
        }
    }

    @Suite
    struct DifferentCodingKeysTests {
        struct ObjectWithCodingKeysEnum: Codable, Equatable {
            let property: Int
            enum CodingKeys: String, CodingKey {
                case property
            }
        }
        @Test
        func objectWithCodingKeysEnum() async throws {
            let data = try #require("d8:propertyi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithCodingKeysEnum.self, from: data)
            #expect(obj == ObjectWithCodingKeysEnum(property: 0))
        }

        struct ObjectWithCodingKeysEnumWithDifferentKey: Codable, Equatable {
            let property: Int
            enum CodingKeys: String, CodingKey {
                case property = "prop"
            }
        }
        @Test
        func objectWithCodingKeysEnumWithDifferentKey() async throws {
            let data = try #require("d4:propi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithCodingKeysEnumWithDifferentKey.self, from: data)
            #expect(obj == ObjectWithCodingKeysEnumWithDifferentKey(property: 0))
        }

        struct ObjectWithCodingKeysEnumWithKeyWithSpace: Codable, Equatable {
            let theProperty: Int
            enum CodingKeys: String, CodingKey {
                case theProperty = "the property"
            }
        }
        @Test
        func objectWithCodingKeysEnumWithKeyWithSpace() async throws {
            let data = try #require("d12:the propertyi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithCodingKeysEnumWithKeyWithSpace.self, from: data)
            #expect(obj == ObjectWithCodingKeysEnumWithKeyWithSpace(theProperty: 0))
        }

        struct StringCodingKey: CodingKey {
            let stringValue: String

            init?(stringValue: String) {
                self.stringValue = stringValue
            }

            init?(intValue: Int) {
                return nil
            }
            var intValue: Int? { nil }
        }

        struct ObjectWithStringCodingKey: Codable, Equatable {
            let property: Int

            init(property: Int) {
                self.property = property
            }

            init(from decoder: any Decoder) throws {
                let rootContainer = try decoder.container(keyedBy: StringCodingKey.self)
                self.property = try rootContainer.decode(Int.self, forKey: StringCodingKey(stringValue: "property")!)
            }
            func encode(to encoder: any Encoder) throws {
                var rootContainer = encoder.container(keyedBy: StringCodingKey.self)
                try rootContainer.encode(self.property, forKey: StringCodingKey(stringValue: "property")!)
            }
        }
        @Test
        func objectWithStringCodingKey() async throws {
            let data = try #require("d8:propertyi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithStringCodingKey.self, from: data)
            #expect(obj == ObjectWithStringCodingKey(property: 0))
        }

        struct ObjectWithStringCodingKeyWithDifferentKey: Codable, Equatable {
            let property: Int

            init(property: Int) {
                self.property = property
            }

            init(from decoder: any Decoder) throws {
                let rootContainer = try decoder.container(keyedBy: StringCodingKey.self)
                self.property = try rootContainer.decode(Int.self, forKey: StringCodingKey(stringValue: "prop")!)
            }
            func encode(to encoder: any Encoder) throws {
                var rootContainer = encoder.container(keyedBy: StringCodingKey.self)
                try rootContainer.encode(self.property, forKey: StringCodingKey(stringValue: "prop")!)
            }
        }
        @Test
        func objectWithStringCodingKeyWithDifferentKey() async throws {
            let data = try #require("d4:propi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithStringCodingKeyWithDifferentKey.self, from: data)
            #expect(obj == ObjectWithStringCodingKeyWithDifferentKey(property: 0))
        }

        struct ObjectWithStringCodingKeyWithKeyWithSpace: Codable, Equatable {
            let theProperty: Int

            init(theProperty property: Int) {
                self.theProperty = property
            }

            init(from decoder: any Decoder) throws {
                let rootContainer = try decoder.container(keyedBy: StringCodingKey.self)
                self.theProperty = try rootContainer.decode(Int.self, forKey: StringCodingKey(stringValue: "the property")!)
            }
            func encode(to encoder: any Encoder) throws {
                var rootContainer = encoder.container(keyedBy: StringCodingKey.self)
                try rootContainer.encode(self.theProperty, forKey: StringCodingKey(stringValue: "the property")!)
            }
        }
        @Test
        func objectWithStringCodingKeyWithKeyWithSpace() async throws {
            let data = try #require("d12:the propertyi0ee".data(using: .utf8)) // utf8 == ascii in this case
            let obj = try BencodeDecoder().decode(ObjectWithStringCodingKeyWithKeyWithSpace.self, from: data)
            #expect(obj == ObjectWithStringCodingKeyWithKeyWithSpace(theProperty: 0))
        }
    }

    @Suite
    struct FailingToDecodeTests {
        struct SingleIntObject: Codable, Equatable { let value: Int }
        @Test
        func objectMissingKeys() async throws {
            let data = try #require("de".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                try BencodeDecoder().decode(SingleIntObject.self, from: data)
            }
        }

        @Test
        func objectWithExtraKey() async throws {
            let data = try #require("d5:otheri0e5:valuei1ee".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                let decoder = BencodeDecoder()
                decoder.unknownKeyDecodingStrategy = .error
                return try decoder.decode(SingleIntObject.self, from: data)
            }
            #expect(throws: Never.self) {
                let decoder = BencodeDecoder()
                return try decoder.decode(SingleIntObject.self, from: data)
            }
        }

        @Test
        func unendedDictionary() async throws {
            let data = try #require("d".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                try BencodeDecoder().decode([String: Int].self, from: data)
            }
        }

        @Test
        func unbalancedDictionary() async throws {
            let data = try #require("d3:keye".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                try BencodeDecoder().decode([String: Int].self, from: data)
            }
        }

        @Test
        func unendedList() async throws {
            let data = try #require("l".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                try BencodeDecoder().decode([Int].self, from: data)
            }
        }

        @Test
        func heterogeneousList() async throws {
            let data = try #require("li0e3:onee".data(using: .utf8)) // utf8 == ascii in this case
            #expect(throws: DecodingError.self) {
                try BencodeDecoder().decode([Int].self, from: data)
            }
        }
    }
}
