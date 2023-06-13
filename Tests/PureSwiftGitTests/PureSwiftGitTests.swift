import XCTest
@testable import PureSwiftGit

let fileURL = URL(fileURLWithPath: #file)
let repoURL = fileURL.deletingLastPathComponent().appendingPathComponent("../../Fixtures/sample-repo")
let repo = Repository(repoURL)

final class PureSwiftGitTests: XCTestCase {
    func testReadBlob() throws {
        let hash = "a5c19667710254f835085b99726e523457150e03"
        let obj = try repo.readObject(hash)
        let expected = Object.blob("Hello, world\n".data(using: .utf8)!)
        XCTAssertEqual(obj, expected)
        XCTAssertEqual(obj.data.sha1, hash)
    }

    func testReadTree() throws {
        let obj = try repo.readObject("c1be61088247955e5bda5984cbc675b7bd2751db")
        let expected = Object.tree([
            TreeItem(mode: "100644", name: "my-file", hash: "a5c19667710254f835085b99726e523457150e03"),
            TreeItem(mode: "40000", name: "nested", hash: "75b335a08dfaa6fe96127d63e514a1ea488ec5be")
        ])
        XCTAssertEqual(obj, expected)
    }

    func testCommit() throws {
        let obj = try repo.readObject("bdf09c59915a4eaa51fe72639a875aeeb0994427")
        let expected = Object.commit(Commit(metadata: [
            .init(key: "tree", value: "c1be61088247955e5bda5984cbc675b7bd2751db"),
            .init(key: "parent", value: "c8ac29c05793b566593c308bee71c2428f505f7c"),
            .init(key: "author", value: "Chris Eidhof <chris@eidhof.nl> 1684850271 +0200"),
            .init(key: "committer", value: "Chris Eidhof <chris@eidhof.nl> 1684850271 +0200")
        ], message: "Second commit\n"))
        XCTAssertEqual(obj, expected)
    }

    func testParseCommit() throws {
        let commit = """
        tree 123
        author 456 test

        The commit message
        """
        let expected = Commit(metadata: [
            .init(key: "tree", value: "123"),
            .init(key: "author", value: "456 test")
        ], message: "The commit message")
        try XCTAssertEqual(commit.parseCommit(), expected)

    }

    func testParseMultilineCommit() throws {
        let commit = """
        multiline first
         second
         third

        The commit message
        """
        let expected = Commit(metadata: [
            .init(key: "multiline", value: "first\nsecond\nthird"),
        ], message: "The commit message")
        try XCTAssertEqual(commit.parseCommit(), expected)
    }

    func testWriteBlob() throws {
        let content = "Sample blob content\n"
        let obj = Object.blob(content.data(using: .utf8)!)
        let hash = try repo.writeObject(obj)
        print(hash)
        XCTFail()
    }
}
