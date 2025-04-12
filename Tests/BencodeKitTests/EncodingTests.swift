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
            let trueData = Data("i\(n)e".utf8)
            #expect(data == trueData)
        }

        @Test func encodeZero() async throws {
            let data = try BencodeEncoder().encode(0)
            let trueData = Data("i0e".utf8)
            #expect(data == trueData)
        }

        @Test("Decode negative integer", .disabled(), arguments: -100 ... -1)
        func encodeNegativeInt(n: Int) async throws {
            let data = try BencodeEncoder().encode(n)
            let trueData = Data("i\(n)e".utf8)
            #expect(data == trueData)
        }
    }

    @Suite
    struct StringEncodingTests {
        @Test
        func emptyString() async throws {
            let data = try BencodeEncoder().encode("")
            let trueData = Data("0:".utf8)
            #expect(data == trueData)
        }

        @Test(arguments: ["Hello, world!"])
        func encodeString(realString: String) async throws {
            let data = try BencodeEncoder().encode(realString)
            let trueData = Data("\(realString.count):\(realString)".utf8)
            #expect(data == trueData)
        }

        // These are DIFFERENT.
        // The first uses the Unicode character "LATIN SMALL LETTER U WITH DIAERESIS"
        // This is represented in UTF-8 by 0xC3 0xBC
        // The second uses the Unicode character "LATIN SMALL LETTER U" followed by the Unicode character "COMBINING DIAERESIS"
        // This is represented in UTF-8 by 0x75 0xCC 0x88
        // As such, their length (in bytes) varies
        @Test(arguments: ["ü", "ü"])
        func encodeMultiByteCharacter(realString: String) async throws {
            let data = try BencodeEncoder().encode(realString)
            let trueStringData = Data(realString.utf8)
            let countData = Data("\(trueStringData.count):".utf8)
            let trueData = countData + trueStringData
            #expect(data == trueData)
        }
    }

    @Suite
    struct DataEncodingTests {
        @Test
        func emptyData() async throws {
            let data = try BencodeEncoder().encode(Data())
            let trueData = Data("0:".utf8)
            #expect(data == trueData)
        }

        struct DataWrapper: Encodable {
            let d: Data
        }
        @Test
        func wrappedEmptyData() async throws {
            let data = try BencodeEncoder().encode(DataWrapper(d: Data()))
            let trueData = Data("d1:d0:e".utf8)
            #expect(data == trueData)
        }
    }

    @Suite
    struct ArrayEncodingTests {
        @Test
        func emptyArray() async throws {
            let data = try BencodeEncoder().encode([Int]())
            let trueData = Data("le".utf8)
            #expect(data == trueData)
        }

        @Test(arguments: [1, 2, 10])
        func nElementIntArray(count: Int) async throws {
            let array = [Int](repeating: 0, count: count)
            let data = try BencodeEncoder().encode(array)
            let correctData = Data("l\(String(repeating: "i0e", count: count))e".utf8)
            #expect(data == correctData)
        }
        
        @Test(arguments: [1, 2, 10])
        func arrayOfEmptyArrays(count: Int) async throws {
            let array = [[Int]](repeating: [], count: count)
            let data = try BencodeEncoder().encode(array)
            let correctData = Data("l\(String(repeating: "le", count: count))e".utf8)
            #expect(data == correctData)
        }
        
        @Test(arguments: [1, 2, 10])
        func arrayOfEmptyDictionaries(count: Int) async throws {
            let array = [[String: Int]](repeating: [:], count: count)
            let data = try BencodeEncoder().encode(array)
            let correctData = Data("l\(String(repeating: "de", count: count))e".utf8)
            #expect(data == correctData)
        }
        
        @Test(arguments: [1, 2, 10], [1, 2, 10])
        func arrayOfArrays(innerCount: Int, outerCount: Int) async throws {
            let array = [[Int]](repeating: [Int](repeating: 0, count: innerCount), count: outerCount)
            let data = try BencodeEncoder().encode(array)
            let innerStr = String(repeating: "i0e", count: innerCount)
            let correctData = Data("l\(String(repeating: "l\(innerStr)e", count: outerCount))e".utf8)
            #expect(data == correctData)
        }
        
        @Test(arguments: [1, 2, 10])
        func arrayOfDictionaries(outerCount: Int) async throws {
            let array = [[String: Int]](repeating: ["one": 1, "two": 2, "three": 3], count: outerCount)
            let data = try BencodeEncoder().encode(array)
            let innerStr = "d3:onei1e5:threei3e3:twoi2ee"
            let correctData = Data("l\(String(repeating: innerStr, count: outerCount))e".utf8)
            #expect(data == correctData)
        }
    }

    @Suite
    struct DictionaryEncodingTests {
        @Test
        func emptyDictionary() async throws {
            let data = try BencodeEncoder().encode([String: Int]())
            let trueData = Data("de".utf8)
            #expect(data == trueData)
        }
        
        @Test
        func dictionaryToInt() async throws {
            let dict = ["one": 1, "two": 2, "three": 3]
            let data = try BencodeEncoder().encode(dict)
            let correctData = Data("d3:onei1e5:threei3e3:twoi2ee".utf8)
            #expect(data == correctData)
        }
        
        @Test
        func dictionaryOfEmptyArrays() async throws {
            let dict: [String: [Int]] = ["one": [], "two": [], "three": []]
            let data = try BencodeEncoder().encode(dict)
            let correctData = Data("d3:onele5:threele3:twolee".utf8)
            #expect(data == correctData)
        }
        
        @Test
        func dictionaryOfEmptyDictionaries() async throws {
            let dict: [String: [String: Int]] = ["one": [:], "two": [:], "three": [:]]
            let data = try BencodeEncoder().encode(dict)
            let correctData = Data("d3:onede5:threede3:twodee".utf8)
            #expect(data == correctData)
        }
        
        @Test
        func dictionaryOfArrays() async throws {
            let dict: [String: [Int]] = ["one": [1], "two": [2, 3], "three": [4, 5, 6]]
            let data = try BencodeEncoder().encode(dict)
            let correctData = Data("d3:oneli1ee5:threeli4ei5ei6ee3:twoli2ei3eee".utf8)
            #expect(data == correctData)
        }
        
        @Test
        func dictionaryOfDictionaries() async throws {
            let innerDict = ["one": 1, "two": 2, "three": 3]
            let dict: [String: [String: Int]] = ["first": innerDict, "second": innerDict, "third": innerDict]
            
            let data = try BencodeEncoder().encode(dict)
            
            let innerStr = "d3:onei1e5:threei3e3:twoi2ee"
            let correctData = Data("d5:first\(innerStr)6:second\(innerStr)5:third\(innerStr)e".utf8)
            
            #expect(data == correctData)
        }
    }
    
    @Suite
    struct ObjectEncodingTests {
        struct EmptyObject: Codable, Equatable {}
        @Test
        func emptyObject() async throws {
            let data = try BencodeEncoder().encode(EmptyObject())
            let correctData = Data("de".utf8)
            #expect(data == correctData)
        }
        
        struct SingleIntObject: Codable, Equatable { let value: Int }
        @Test
        func singleIntObject() async throws {
            let data = try BencodeEncoder().encode(SingleIntObject(value: 0))
            let correctData = Data("d5:valuei0ee".utf8)
            #expect(data == correctData)
        }
        
        struct SingleStringObject: Codable, Equatable { let value: String }
        @Test
        func singleStringObject() async throws {
            let data = try BencodeEncoder().encode(SingleStringObject(value: "0"))
            let correctData = Data("d5:value1:0e".utf8)
            #expect(data == correctData)
        }
        
        struct DoubleIntObject: Codable, Equatable { let v1: Int; let v2: Int }
        @Test
        func doubleIntObject() async throws {
            let data = try BencodeEncoder().encode(DoubleIntObject(v1: 3, v2: 4))
            let correctData = Data("d2:v1i3e2:v2i4ee".utf8)
            #expect(data == correctData)
        }
        
        struct DoubleStringObject: Codable, Equatable { let v1: String; let v2: String }
        @Test
        func doubleStringObject() async throws {
            let data = try BencodeEncoder().encode(DoubleStringObject(v1: "3", v2: "4"))
            let correctData = Data("d2:v11:32:v21:4e".utf8)
            #expect(data == correctData)
        }
        
        struct IntAndStringObject: Codable, Equatable { let ival: Int; let sval: String }
        @Test
        func intAndStringObject() async throws {
            let data = try BencodeEncoder().encode(IntAndStringObject(ival: 0, sval: "0"))
            let correctData = Data("d4:ivali0e4:sval1:0e".utf8)
            #expect(data == correctData)
        }
        
        struct NestedObject: Codable, Equatable { let obj: SingleIntObject }
        @Test
        func nestedObject() async throws {
            let data = try BencodeEncoder().encode(NestedObject(obj: SingleIntObject(value: 0)))
            let correctData = Data("d3:obj\("d5:valuei0ee")e".utf8)
            #expect(data == correctData)
        }
        
        struct NestedNestedObject: Codable, Equatable { let outer: NestedObject }
        @Test
        func nestedNestedObject() async throws {
            let obj = NestedNestedObject(outer: NestedObject(obj: SingleIntObject(value: 0)))
            let data = try BencodeEncoder().encode(obj)
            let correctData = Data("d5:outer\("d3:obj\("d5:valuei0ee")e")e".utf8)
            #expect(data == correctData)
        }

        struct ObjectWithOptionalValue: Codable, Equatable { let o: Int? }
        @Test
        func objectWithNilValue() async throws {
            let obj = ObjectWithOptionalValue(o: nil)
            let data = try BencodeEncoder().encode(obj)
            let correctData = Data("de".utf8)
            #expect(data == correctData)
        }
    }
}
