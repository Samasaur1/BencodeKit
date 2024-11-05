# BencodeKit

This package provides the `BencodeEncoder` and `BencodeDecoder` types, which allow converting `Codable` structs to data and back.

### Strengths

### Limitations

We are limited to the types that bencode supports. This means that for things such as `Bool`s, the two options are to immediately crash (what we do), to encode them as types that bencode supports, or to introduce a `BenCodable` struct that conforms to `Codable` but doesn't allow `Bool`s or other non-bencode-supported types.

### Notes

A huge amount of credit goes to <https://github.com/Flight-School/MessagePack/tree/master>
