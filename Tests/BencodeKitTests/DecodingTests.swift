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
    }
}
