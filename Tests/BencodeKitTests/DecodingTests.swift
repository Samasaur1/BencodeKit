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
        @Test(.disabled())
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
    }

    @Suite
    struct DictionaryDecodingTests {
        @Test
        func emptyDictionary() async throws {
            let data = try #require("de".data(using: .utf8)) // utf8 == ascii in this case
            let a = try BencodeDecoder().decode([String: Int].self, from: data)
            #expect(a == [:])
        }
    }
}
