import Foundation

@main
struct DocumentStoreChecks {
  static func main() throws {
    let manager = FileManager.default
    let fixture = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let cache = fixture.appendingPathComponent("cache", isDirectory: true)
    let docs = fixture.appendingPathComponent("documents", isDirectory: true)
    try manager.createDirectory(at: cache, withIntermediateDirectories: true)
    try manager.createDirectory(at: docs, withIntermediateDirectories: true)
    defer { try? manager.removeItem(at: fixture) }
    let source = cache.appendingPathComponent("source.download")
    let bytes = Data("%PDF-test-document".utf8)
    try bytes.write(to: source)
    let store = try DocumentStore(caches: cache, documents: docs)
    var checks = 0
    func require(_ condition: Bool) {
      precondition(condition, "iOS document store check failed")
      checks += 1
    }
    func rejects(_ operation: () throws -> Void) {
      do {
        try operation()
        preconditionFailure("iOS document store accepted an invalid input")
      } catch {
        checks += 1
      }
    }
    let saved = try store.save(path: source.path, name: "Proposal.pdf", mime: "application/pdf")
    require(saved.lastPathComponent == "Proposal.pdf")
    let savedBytes = try Data(contentsOf: saved)
    require(savedBytes == bytes)
    require(manager.fileExists(atPath: source.path))
    let opened = try store.document(uri: saved.absoluteString, mime: "application/pdf")
    require(opened == saved)
    let duplicate = try store.save(path: source.path, name: "Proposal.pdf", mime: "application/pdf")
    require(duplicate != saved)
    require(duplicate.pathExtension == "pdf")
    let originalBytes = try Data(contentsOf: saved)
    require(originalBytes == bytes)
    for name in ["../outside.pdf", "nested/file.pdf", "..", ".", "", String(repeating: "a", count: 121), "file.pdf\n"] {
      rejects { _ = try store.save(path: source.path, name: name, mime: "application/pdf") }
    }
    rejects { _ = try store.save(path: source.path, name: "file.pdf", mime: "text/plain; charset=utf-8") }
    rejects { _ = try store.save(path: source.path, name: "file.pdf", mime: "application/pdf\n") }
    let outside = fixture.appendingPathComponent("outside.pdf")
    try bytes.write(to: outside)
    rejects { _ = try store.save(path: outside.path, name: "file.pdf", mime: "application/pdf") }
    rejects { _ = try store.document(uri: outside.absoluteString, mime: "application/pdf") }
    rejects { _ = try store.document(uri: "https://crm.justsmartchoice.com/file.pdf", mime: "application/pdf") }
    rejects { _ = try store.document(uri: saved.absoluteString + "?preview=1", mime: "application/pdf") }
    let empty = cache.appendingPathComponent("empty.download")
    try Data().write(to: empty)
    rejects { _ = try store.save(path: empty.path, name: "empty.pdf", mime: "application/pdf") }
    rejects { _ = try store.save(path: cache.path, name: "directory.pdf", mime: "application/pdf") }
    let linked = cache.appendingPathComponent("linked.download")
    try manager.createSymbolicLink(at: linked, withDestinationURL: outside)
    rejects { _ = try store.save(path: linked.path, name: "linked.pdf", mime: "application/pdf") }
    let escaped = docs.appendingPathComponent("SmartChoice/linked.pdf")
    try manager.createSymbolicLink(at: escaped, withDestinationURL: outside)
    rejects { _ = try store.document(uri: escaped.absoluteString, mime: "application/pdf") }
    let oversized = cache.appendingPathComponent("oversized.download")
    require(manager.createFile(atPath: oversized.path, contents: nil))
    let handle = try FileHandle(forWritingTo: oversized)
    try handle.truncate(atOffset: UInt64(DocumentStore.maxBytes + 1))
    try handle.close()
    rejects { _ = try store.save(path: oversized.path, name: "oversized.pdf", mime: "application/pdf") }
    let backup = docs.appendingPathComponent("retained-folder")
    try manager.moveItem(at: docs.appendingPathComponent("SmartChoice"), to: backup)
    try manager.createSymbolicLink(at: docs.appendingPathComponent("SmartChoice"), withDestinationURL: fixture)
    rejects { _ = try store.document(uri: docs.appendingPathComponent("SmartChoice/outside.pdf").absoluteString, mime: "application/pdf") }
    rejects { _ = try store.save(path: source.path, name: "outside-copy.pdf", mime: "application/pdf") }
    print("\(checks) iOS document storage checks passed (Foundation/macOS; device UI requires Xcode)")
  }
}
