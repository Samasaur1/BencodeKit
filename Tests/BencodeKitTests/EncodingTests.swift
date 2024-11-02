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
            let trueData = "i\(n)e".data(using: .utf8)! // utf8 == ascii in this case
            #expect(data == trueData)
        }

        @Test func encodeZero() async throws {
            let data = try BencodeEncoder().encode(0)
            let trueData = "i0e".data(using: .utf8)! // utf8 == ascii in this case
            #expect(data == trueData)
        }

        @Test("Decode negative integer", .disabled(), arguments: -100 ... -1)
        func encodeNegativeInt(n: Int) async throws {
            let data = try BencodeEncoder().encode(n)
            let trueData = "i\(n)e".data(using: .utf8)! // utf8 == ascii in this case
            #expect(data == trueData)
        }
    }

    @Suite
    struct StringEncodingTests {
        @Test
        func emptyString() async throws {
            let data = try BencodeEncoder().encode("")
            let trueData = "0:".data(using: .utf8)! // utf8 == ascii in this case
            #expect(data == trueData)
        }

        @Test(arguments: ["Hello, world!"])
        func encodeString(realString: String) async throws {
            do {
                let data = try BencodeEncoder().encode(realString)
                let trueData = "\(realString.count):\(realString)".data(using: .ascii)!
                #expect(data == trueData)
            }
            let data = try BencodeEncoder().encode(realString)
            let trueData = "\(realString.count):\(realString)".data(using: .utf8)!
            #expect(data == trueData)
        }
    }

    @Suite
    struct DataEncodingTests {
        @Test(.disabled())
        func emptyData() async throws {
            let data = try BencodeEncoder().encode(Data())
            let trueData = "0:".data(using: .utf8)! // utf8 == ascii in this case
            #expect(data == trueData)
        }

        struct DataWrapper: Encodable {
            let d: Data
        }
        @Test
        func wrappedEmptyData() async throws {
            let data = try BencodeEncoder().encode(DataWrapper(d: Data()))
            let trueData = "d1:d0:e".data(using: .utf8)! // utf8 == ascii in this case
            #expect(data == trueData)
        }
    }

    @Suite
    struct ArrayEncodingTests {
        @Test
        func emptyArray() async throws {
            let data = try BencodeEncoder().encode([Int]())
            let trueData = "le".data(using: .utf8)! // utf8 == ascii in this case
            #expect(data == trueData)
        }
    }
}
