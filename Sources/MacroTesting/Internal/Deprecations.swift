import InlineSnapshotTesting
import SwiftDiagnostics
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import XCTest

// MARK: Deprecated after 0.1.0

@available(*, deprecated, message: "Re-record this assertion")
public func assertMacro(
  _ macros: [String: Macro.Type]? = nil,
  record isRecording: Bool? = nil,
  of originalSource: () throws -> String,
  matches expandedOrDiagnosedSource: () -> String,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  guard isRecording ?? MacroTestingConfiguration.current.isRecording else {
    XCTFail("Re-record this assertion", file: file, line: line)
    return
  }
  assertMacro(
    macros,
    record: true,
    of: originalSource,
    file: file,
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
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  assertMacro(
    Dictionary(macros: macros),
    record: isRecording,
    of: originalSource,
    matches: expandedOrDiagnosedSource,
    file: file,
    function: function,
    line: line,
    column: column
  )
}

@available(
  *, deprecated, message: "Delete 'applyFixIts' and 'matches' and re-record this assertion"
)
public func assertMacro(
  _ macros: [String: Macro.Type]? = nil,
  applyFixIts: Bool,
  record isRecording: Bool? = nil,
  of originalSource: () throws -> String,
  matches expandedOrDiagnosedSource: () -> String,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  XCTFail("Delete 'matches' and re-record this assertion", file: file, line: line)
}

@available(
  *, deprecated, message: "Delete 'applyFixIts' and 'matches' and re-record this assertion"
)
public func assertMacro(
  _ macros: [Macro.Type],
  applyFixIts: Bool,
  record isRecording: Bool? = nil,
  of originalSource: () throws -> String,
  matches expandedOrDiagnosedSource: () -> String,
  file: StaticString = #filePath,
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
    file: file,
    function: function,
    line: line,
    column: column
  )
}
