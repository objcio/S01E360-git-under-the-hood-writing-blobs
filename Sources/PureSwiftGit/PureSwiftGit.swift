import Foundation

public struct TreeItem: Hashable {
    var mode: String
    var name: String
    var hash: String
}

public struct KeyValue: Hashable {
    public var key: String
    public var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public struct Commit: Hashable {
    var metadata: [KeyValue]
    var message: String
}

public enum Object: Hashable {
    case blob(Data)
    case commit(Commit)
    case tree([TreeItem])
}

extension Object {
    var data: Data {
        switch self {
        case .blob(let data):
            return "blob \(data.count)".data(using: .utf8)! + [0] + data
        case .commit(let commit):
            fatalError("TODO")
        case .tree(let array):
            fatalError("TODO")
        }
    }
}

extension Data {
    mutating func parseTreeItems() throws -> [TreeItem] {
        var result: [TreeItem] = []
        while !isEmpty {
            try result.append(parseTreeItem())
        }
        return result
    }

    mutating func parseTreeItem() throws -> TreeItem {
        let mode = String(decoding: remove(upTo: 0x20), as: UTF8.self)
        let name = String(decoding: remove(upTo: 0), as: UTF8.self)
        let hashData = prefix(20)
        removeFirst(20)
        let hash = hashData.hexString
        return TreeItem(mode: mode, name: name, hash: hash)
    }
}

extension String {
    func parseCommit() throws -> Commit {
        var s = self[...]
        return try s.parseCommit()
    }
}

public struct ParseError: Error { }

extension Substring {
    mutating func parseCommit() throws -> Commit {
        var result: [KeyValue] = []
        while !isEmpty {
            let key = remove(while: { $0 != " " && $0 != "\n" })
            if key.isEmpty {
                guard popFirst() == "\n" else { throw ParseError() }
                break
            } else {
                guard popFirst() == " " else {
                    throw ParseError()
                }
                var value = String(remove(while: { $0 != "\n" }))
                _ = popFirst()
                while first == " " {
                    removeFirst()
                    let cont = remove(while: { $0 != "\n" })
                    _ = popFirst()
                    value.append("\n")
                    value.append(contentsOf: cont)
                }
                result.append(.init(key: String(key), value: value))
            }
        }
        return Commit(metadata: result, message: String(self))
    }
}

public struct Repository {
    var url: URL
    init(_ url: URL) {
        self.url = url
    }

    var gitURL: URL {
        url.appendingPathComponent(".git")
    }

    func readObject(_ hash: String) throws -> Object {
        // todo verify that this is an actual hash
        let objectPath = "\(hash.prefix(2))/\(hash.dropFirst(2))"
        let data = try Data(contentsOf: gitURL.appendingPathComponent("objects/\(objectPath)")).decompressed
        var remainder = data
        let typeStr = String(decoding: remainder.remove(upTo: 0x20), as: UTF8.self)
        remainder.remove(upTo: 0)
        switch typeStr {
        case "blob": return .blob(remainder)
        case "tree": return try .tree(remainder.parseTreeItems())
        case "commit":
            let str = String(decoding: remainder, as: UTF8.self)
            return try .commit(str.parseCommit())
        default: fatalError()
        }
    }

    func writeObject(_ obj: Object) throws -> String {
        let data = obj.data
        let hash = data.sha1
        let objectPath = "\(hash.prefix(2))/\(hash.dropFirst(2))"
        let url = gitURL.appendingPathComponent("objects").appendingPathComponent(objectPath)
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.compressed.write(to: url)
        return hash
    }
}

extension Data {
    @discardableResult
    mutating func remove(upTo separator: Element) -> Data {
        let part = prefix(while: { $0 != separator })
        removeFirst(part.count)
        _ = popFirst()
        return part
    }
}

extension RangeReplaceableCollection {
    @discardableResult
    mutating func remove(while cond: (Element) -> Bool) -> SubSequence {
        let part = prefix(while: cond)
        removeFirst(part.count)
        return part
    }
}
