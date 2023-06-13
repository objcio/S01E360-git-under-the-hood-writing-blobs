import Foundation
import Compression
import CryptoKit

// From https://github.com/mezhevikin/Zlib/blob/master/Sources/Zlib/Zlib.swift

extension Data {
    var decompressed: Data {
        let size = 8_000_000
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer { buffer.deallocate() }
        let result = dropFirst(2).withUnsafeBytes({
            let read = compression_decode_buffer(
                buffer,
                size,
                $0.baseAddress!.bindMemory(
                    to: UInt8.self,
                    capacity: 1
                ),
                $0.count,
                nil,
                COMPRESSION_ZLIB
            )
            return Data(bytes: buffer, count: read)
        })
        return result
    }

    var compressed: Data {
        let size = 8_000_000
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer { buffer.deallocate() }
        let result = withUnsafeBytes({
            let written = compression_encode_buffer(buffer, size, $0.baseAddress!.bindMemory(
                to: UInt8.self,
                capacity: 1
            ), $0.count, nil, COMPRESSION_ZLIB)
            return Data(bytes: buffer, count: written)
        })
        var checksum = self.adler32.bigEndian
        let checksumData = Data(bytes: &checksum, count: 4)
        return [0x78, 0x01] + result + checksumData
    }

    var adler32: UInt32 {
        var a: UInt32 = 1
        var b: UInt32 = 0
        for byte in self {
            a = (a + UInt32(byte)) % 65521
            b = (b + a) % 65521
        }
        return (b << 16) | a
    }

    var hexString: String {
        map { byte in
            let result = String(byte, radix: 16)
            return result.count == 1 ? "0\(result)" : result
        }.joined()
    }

    var sha1: String {
        let digest = Insecure.SHA1.hash(data: self)
        return Data(digest).hexString
    }
}
