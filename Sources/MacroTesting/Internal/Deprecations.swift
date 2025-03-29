import InlineSnapshotTesting
@_spi(Internals) import SnapshotTesting
import SwiftDiagnostics
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import XCTest

#if canImport(Testing)
  import Testing
#endif

// MARK: Deprecated after 0.6.0

#if canImport(Testing) && compiler(>=6)
  extension Trait where Self == _MacrosTestTrait {

    @available(*, deprecated, message: "Use `macros(_:indentationWidth:record:)` instead")
    public static func macros(
      indentationWidth: Trivia? = nil,
      record: SnapshotTestingConfiguration.Record? = nil,
      macros: [String: Macro.Type]? = nil
    ) -> Self {
      Self.macros(macros, indentationWidth: indentationWidth, record: record)
    }

    @available(*, deprecated, message: "Use `macros(_:indentationWidth:record:)` instead")
    public static func macros(
      indentationWidth: Trivia? = nil,
      record: SnapshotTestingConfiguration.Record? = nil,
      macros: [Macro.Type]? = nil
    ) -> Self {
      Self.macros(macros, indentationWidth: indentationWidth, record: record)
    }
  }
#endif

// MARK: Deprecated after 0.4.2

@available(iOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  macOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(tvOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  visionOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(
  watchOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@_disfavoredOverload
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  isRecording: Bool? = nil,
  macros: [String: Macro.Type]? = nil,
  operation: () async throws -> R
) async rethrows {
  var configuration = MacroTestingConfiguration.current
  if let indentationWidth { configuration.indentationWidth = indentationWidth }
  let record: SnapshotTestingConfiguration.Record? = isRecording.map { $0 ? .all : .missing }
  if let macros { configuration.macros = macros }
  _ = try await withSnapshotTesting(record: record) {
    try await MacroTestingConfiguration.$current.withValue(configuration) {
      try await operation()
    }
  }
}

@available(iOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  macOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(tvOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  visionOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(
  watchOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@_disfavoredOverload
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  isRecording: Bool? = nil,
  macros: [String: Macro.Type]? = nil,
  operation: () throws -> R
) rethrows {
  var configuration = MacroTestingConfiguration.current
  if let indentationWidth { configuration.indentationWidth = indentationWidth }
  let record: SnapshotTestingConfiguration.Record? = isRecording.map { $0 ? .all : .missing }
  if let macros { configuration.macros = macros }
  _ = try withSnapshotTesting(record: record) {
    try MacroTestingConfiguration.$current.withValue(configuration) {
      try operation()
    }
  }
}

@available(iOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  macOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(tvOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  visionOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(
  watchOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@_disfavoredOverload
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  isRecording: Bool? = nil,
  macros: [Macro.Type],
  operation: () async throws -> R
) async rethrows {
  try await withMacroTesting(
    indentationWidth: indentationWidth,
    isRecording: isRecording,
    macros: Dictionary(macros: macros),
    operation: operation
  )
}

@available(iOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  macOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(tvOS, deprecated, renamed: "withMacroTesting(indentationWidth:record:macros:operation:)")
@available(
  visionOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@available(
  watchOS,
  deprecated,
  renamed: "withMacroTesting(indentationWidth:record:macros:operation:)"
)
@_disfavoredOverload
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  isRecording: Bool? = nil,
  macros: [Macro.Type],
  operation: () throws -> R
) rethrows {
  try withMacroTesting(
    indentationWidth: indentationWidth,
    isRecording: isRecording,
    macros: Dictionary(macros: macros),
    operation: operation
  )
}

// MARK: Deprecated after 0.1.0

@available(*, deprecated, message: "Re-record this assertion")
public func assertMacro(
  _ macros: [String: Macro.Type]? = nil,
  record isRecording: Bool? = nil,
  of originalSource: () throws -> String,
  matches expandedOrDiagnosedSource: () -> String,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  guard isRecording ?? (SnapshotTestingConfiguration.current?.record == .all) else {
    recordIssue(
      "Re-record this assertion",
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
    return
  }
  assertMacro(
    macros,
    record: true,
    of: originalSource,
    file: filePath,
    function: function,
    line: line,
    column: column
  )
}

@available(*, deprecated, message: "Re-record this assertion")
public func assertMacro(
  _ macros: [Macro.Type],
  record isRecording: Bool? = nil,
  of originalSource: () throws -> String,
  matches expandedOrDiagnosedSource: () -> String,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  assertMacro(
    Dictionary(macros: macros),
    record: isRecording,
    of: originalSource,
    matches: expandedOrDiagnosedSource,
    fileID: fileID,
    file: filePath,
    function: function,
    line: line,
    column: column
  )
}

@available(
  *,
  deprecated,
  message: "Delete 'applyFixIts' and 'matches' and re-record this assertion"
)
public func assertMacro(
  _ macros: [String: Macro.Type]? = nil,
  applyFixIts: Bool,
  record isRecording: Bool? = nil,
  of originalSource: () throws -> String,
  matches expandedOrDiagnosedSource: () -> String,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  recordIssue(
    "Delete 'matches' and re-record this assertion",
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

@available(
  *,
  deprecated,
  message: "Delete 'applyFixIts' and 'matches' and re-record this assertion"
)
public func assertMacro(
  _ macros: [Macro.Type],
  applyFixIts: Bool,
  record isRecording: Bool? = nil,
  of originalSource: () throws -> String,
  matches expandedOrDiagnosedSource: () -> String,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  assertMacro(
    Dictionary(macros: macros),
    applyFixIts: applyFixIts,
    record: isRecording,
    of: originalSource,
    matches: expandedOrDiagnosedSource,
    fileID: fileID,
    file: filePath,
    function: function,
    line: line,
    column: column
  )
}
