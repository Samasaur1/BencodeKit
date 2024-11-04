import Testing
import Foundation
@testable import BencodeKit

@Suite
struct EncodingTests {
    @Suite
    struct IntEncodingTests {
        @Test("Encode positive integer", arguments: 1...100)
        func encodePositiveInt(n: Int) async throws {
            let data = try BencodeEncoder().encode(n)
            let trueData = try #require("i\(n)e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }

        @Test func encodeZero() async throws {
            let data = try BencodeEncoder().encode(0)
            let trueData = try #require("i0e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }

        @Test("Decode negative integer", .disabled(), arguments: -100 ... -1)
        func encodeNegativeInt(n: Int) async throws {
            let data = try BencodeEncoder().encode(n)
            let trueData = try #require("i\(n)e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }
    }

    @Suite
    struct StringEncodingTests {
        @Test
        func emptyString() async throws {
            let data = try BencodeEncoder().encode("")
            let trueData = try #require("0:".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }

        @Test(arguments: ["Hello, world!"])
        func encodeString(realString: String) async throws {
            do {
                let data = try BencodeEncoder().encode(realString)
                let trueData = try #require("\(realString.count):\(realString)".data(using: .ascii))
                #expect(data == trueData)
            }
            let data = try BencodeEncoder().encode(realString)
            let trueData = try #require("\(realString.count):\(realString)".data(using: .utf8))
            #expect(data == trueData)
        }
    }

    @Suite
    struct DataEncodingTests {
        @Test
        func emptyData() async throws {
            let data = try BencodeEncoder().encode(Data())
            let trueData = try #require("0:".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }

        struct DataWrapper: Encodable {
            let d: Data
        }
        @Test
        func wrappedEmptyData() async throws {
            let data = try BencodeEncoder().encode(DataWrapper(d: Data()))
            let trueData = try #require("d1:d0:e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }
    }

    @Suite
    struct ArrayEncodingTests {
        @Test
        func emptyArray() async throws {
            let data = try BencodeEncoder().encode([Int]())
            let trueData = try #require("le".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }

        @Test(arguments: [1, 2, 10])
        func nElementIntArray(count: Int) async throws {
            let array = [Int](repeating: 0, count: count)
            let data = try BencodeEncoder().encode(array)
            let correctData = try #require("l\(String(repeating: "i0e", count: count))e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
    }

    @Suite
    struct DictionaryEncodingTests {
        @Test
        func emptyDictionary() async throws {
            let data = try BencodeEncoder().encode([String: Int]())
            let trueData = try #require("de".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == trueData)
        }
        
        @Test
        func dictionaryToInt() async throws {
            let dict = ["one": 1, "two": 2, "three": 3]
            let data = try BencodeEncoder().encode(dict)
            let correctData = try #require("d3:onei1e5:threei3e3:twoi2ee".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
    }
    
    @Suite
    struct ObjectEncodingTests {
        struct EmptyObject: Codable, Equatable {}
        @Test
        func emptyObject() async throws {
            let data = try BencodeEncoder().encode(EmptyObject())
            let correctData = try #require("de".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
        
        struct SingleIntObject: Codable, Equatable { let value: Int }
        @Test
        func singleIntObject() async throws {
            let data = try BencodeEncoder().encode(SingleIntObject(value: 0))
            let correctData = try #require("d5:valuei0ee".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
        
        struct SingleStringObject: Codable, Equatable { let value: String }
        @Test
        func singleStringObject() async throws {
            let data = try BencodeEncoder().encode(SingleStringObject(value: "0"))
            let correctData = try #require("d5:value1:0e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
        
        struct DoubleIntObject: Codable, Equatable { let v1: Int; let v2: Int }
        @Test
        func doubleIntObject() async throws {
            let data = try BencodeEncoder().encode(DoubleIntObject(v1: 3, v2: 4))
            let correctData = try #require("d2:v1i3e2:v2i4ee".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
        
        struct DoubleStringObject: Codable, Equatable { let v1: String; let v2: String }
        @Test
        func doubleStringObject() async throws {
            let data = try BencodeEncoder().encode(DoubleStringObject(v1: "3", v2: "4"))
            let correctData = try #require("d2:v11:32:v21:4e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
        
        struct IntAndStringObject: Codable, Equatable { let ival: Int; let sval: String }
        @Test
        func intAndStringObject() async throws {
            let data = try BencodeEncoder().encode(IntAndStringObject(ival: 0, sval: "0"))
            let correctData = try #require("d4:ivali0e4:sval1:0e".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
        
        struct NestedObject: Codable, Equatable { let obj: SingleIntObject }
        @Test
        func nestedObject() async throws {
            let data = try BencodeEncoder().encode(NestedObject(obj: SingleIntObject(value: 0)))
            let correctData = try #require("d3:objd5:valuei0eee".data(using: .utf8)) // utf8 == ascii in this case
            #expect(data == correctData)
        }
    }
}
