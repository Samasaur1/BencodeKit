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
    }
}
