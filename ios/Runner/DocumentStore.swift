import Foundation

/// Copies temporary CRM downloads into this app's Files folder only.
final class DocumentStore {
  enum Failure: Error {
    case invalidDocument
  }

  static let maxBytes = 100 * 1024 * 1024
  private let manager: FileManager
  private let caches: URL
  private let documents: URL
  private var downloads: URL { documents.appendingPathComponent("SmartChoice", isDirectory: true) }

  init(
    manager: FileManager = .default,
    caches: URL? = nil,
    documents: URL? = nil
  ) throws {
    self.manager = manager
    self.caches = try caches ?? manager.url(
      for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    self.documents = try documents ?? manager.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  }

  func save(path: String, name: String, mime: String) throws -> URL {
    guard validName(name), validMime(mime) else { throw Failure.invalidDocument }
    let input = URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL
    guard contained(input, in: caches), try regularDocument(input) else {
      throw Failure.invalidDocument
    }
    try manager.createDirectory(at: downloads, withIntermediateDirectories: true)
    let directory = downloads.resolvingSymlinksInPath().standardizedFileURL
    guard contained(directory, in: documents) else { throw Failure.invalidDocument }
    try protect(directory)

    var output = directory.appendingPathComponent(name)
    if manager.fileExists(atPath: output.path) {
      let sourceName = (name as NSString)
      let suffix = sourceName.pathExtension
      let stem = sourceName.deletingPathExtension
      let unique = "\(stem)-\(UUID().uuidString)" + (suffix.isEmpty ? "" : ".\(suffix)")
      output = directory.appendingPathComponent(unique)
    }
    do {
      try manager.copyItem(at: input, to: output)
      try protect(output)
      return output
    } catch {
      try? manager.removeItem(at: output)
      throw error
    }
  }

  func document(uri: String, mime: String) throws -> URL {
    guard validMime(mime), let url = URL(string: uri), url.isFileURL,
      (url.host == nil || url.host == ""), url.query == nil, url.fragment == nil else {
      throw Failure.invalidDocument
    }
    let resolved = url.resolvingSymlinksInPath().standardizedFileURL
    guard contained(resolved, in: downloads), contained(resolved, in: documents),
      try regularDocument(resolved) else {
      throw Failure.invalidDocument
    }
    return resolved
  }

  private func contained(_ url: URL, in directory: URL) -> Bool {
    let root = directory.resolvingSymlinksInPath().standardizedFileURL.path
    return url.path.hasPrefix(root + "/")
  }

  private func regularDocument(_ url: URL) throws -> Bool {
    let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
    guard values.isRegularFile == true, let size = values.fileSize else { return false }
    return size > 0 && size <= Self.maxBytes
  }

  private func validName(_ name: String) -> Bool {
    name.range(of: "^[a-zA-Z0-9._ -]{1,120}$", options: .regularExpression)
      == name.startIndex..<name.endIndex
      && name != "." && name != ".."
  }

  private func validMime(_ mime: String) -> Bool {
    mime.range(of: "^[a-zA-Z0-9.+-]+/[a-zA-Z0-9.+-]+$", options: .regularExpression)
      == mime.startIndex..<mime.endIndex
  }

  private func protect(_ url: URL) throws {
    var secured = url
    var values = URLResourceValues()
    // Downloaded customer documents can be fetched again and do not belong in backups.
    values.isExcludedFromBackup = true
    try secured.setResourceValues(values)
    #if os(iOS)
    try manager.setAttributes(
      [.protectionKey: FileProtectionType.complete], ofItemAtPath: secured.path)
    #endif
  }
}
