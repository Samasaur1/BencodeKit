# BencodeKit

This package provides the `BencodeEncoder` and `BencodeDecoder` types, which allow converting `Codable` structs to data and back.

### Usage

See the `Tests/BencodeKitTests` directory for example usage.

### Strengths

This library integrates well with the existing `Codable` protocols and follows the same pattern as `JSONEncoder`/`JSONDecoder`, which means its use is familiar to Swift developers.

### Limitations

We are limited to the types that bencode supports. This means that for things such as `Bool`s, the two options are to immediately crash (what we do), to encode them as types that bencode supports, or to introduce a `BenCodable` struct that conforms to `Codable` but doesn't allow `Bool`s or other non-bencode-supported types.

There are also some cases where this library will crash instead of throwing an error that can be handled, due to how it is structured internally. This is on my list to improve.

### Notes

A huge amount of credit goes to <https://github.com/Flight-School/MessagePack/tree/master>
