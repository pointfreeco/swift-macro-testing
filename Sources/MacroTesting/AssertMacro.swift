import InlineSnapshotTesting
@_spi(Internals) @preconcurrency import SnapshotTesting
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

/// Asserts that a given Swift source string matches an expected string with all macros expanded.
///
/// To write a macro assertion, you simply pass the mapping of macros to expand along with the
/// source code that should be expanded:
///
/// ```swift
/// func testMacro() {
///   assertMacro(["stringify": StringifyMacro.self]) {
///     """
///     #stringify(a + b)
///     """
///   }
/// }
/// ```
///
/// When this test is run, the result of the expansion is automatically written to the test file,
/// inlined, as a trailing argument:
///
/// ```swift
/// func testMacro() {
///   assertMacro(["stringify": StringifyMacro.self]) {
///     """
///     #stringify(a + b)
///     """
///   } expansion: {
///     """
///     (a + b, "a + b")
///     """
///   }
/// }
/// ```
///
/// If the expansion fails, diagnostics are inlined instead:
///
/// ```swift
/// assertMacro(["MetaEnum": MetaEnumMacro.self]) {
///   """
///   @MetaEnum struct Cell {
///     let integer: Int
///     let text: String
///     let boolean: Bool
///   }
///   """
/// } diagnostics: {
///   """
///   @MetaEnum struct Cell {
///   ┬────────
///   ╰─ 🛑 '@MetaEnum' can only be attached to an enum, not a struct
///     let integer: Int
///     let text: String
///     let boolean: Bool
///   }
///   """
/// }
/// ```
///
/// > Tip: Use ``withMacroTesting(indentationWidth:record:macros:operation:)-7cm1s`` in your
/// > test case's `invokeTest` to avoid the repetitive work of passing the macro mapping to every
/// > `assertMacro`:
/// >
/// > ```swift
/// > override func invokeTest() {
/// >   // By wrapping each test with macro testing configuration...
/// >   withMacroTesting(macros: ["stringify": StringifyMacro.self]) {
/// >     super.invokeTest()
/// >   }
/// > }
/// >
/// > func testMacro() {
/// >   assertMacro {  // ...we can omit it from the assertion.
/// >     """
/// >     #stringify(a + b)
/// >     """
/// >   } expansion: {
/// >     """
/// >     (a + b, "a + b")
/// >     """
/// >   }
/// > }
/// > ```
///
/// - Parameters:
///   - macros: The macros to expand in the original source string. Required, either implicitly via
///     ``withMacroTesting(indentationWidth:record:macros:operation:)-7cm1s``, or explicitly
///     via this parameter.
///   - indentationWidth: The `Trivia` for setting indentation during macro expansion
///     (e.g., `.spaces(2)`). Defaults to the original source's indentation if unspecified. If the
///     original source lacks indentation, it defaults to `.spaces(4)`.
///   - record: The recording strategy to use for the macro expansion. If not provided, it defaults to the current
///     configuration, which can be set using the `SNAPSHOT_TESTING_RECORD` environment variable
///   - originalSource: A string of Swift source code.
///   - diagnosedSource: Swift source code annotated with expected diagnostics.
///   - fixedSource: Swift source code with expected fix-its applied.
///   - expandedSource: Expected Swift source string with macros expanded.
///   - fileID: The file ID where the assertion occurs.
///   - filePath: The file where the assertion occurs. The default is the filename of the test case
///     where you call this function.
///   - function: The function where the assertion occurs. The default is the name of the test
///     method where you call this function.
///   - line: The line where the assertion occurs. The default is the line number where you call
///     this function.
///   - column: The column where the assertion occurs. The default is the column where you call this
///     function.
public func assertMacro(
  _ macros: [String: Macro.Type]? = nil,
  indentationWidth: Trivia? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  of originalSource: () throws -> String,
  diagnostics diagnosedSource: (() -> String)? = nil,
  fixes fixedSource: (() -> String)? = nil,
  expansion expandedSource: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  var indentationWidth =
    indentationWidth
    ?? MacroTestingConfiguration.current.indentationWidth
  var macros =
    macros
    ?? MacroTestingConfiguration.current.macros
  var record =
    record
    ?? SnapshotTestingConfiguration.current?.record
  #if canImport(Testing) && swift(<6.1)
    indentationWidth =
      indentationWidth
      ?? Test.current?.indentationWidth
    macros =
      macros
      ?? Test.current?.macros
    record =
      record
      ?? Test.current?.record
  #endif
  withMacroTesting(indentationWidth: indentationWidth, record: record, macros: macros) {
    guard let macros, !macros.isEmpty else {
      recordIssue(
        """
        No macros configured for this assertion. Pass a mapping to this function, e.g.:

            assertMacro(["stringify": StringifyMacro.self]) { … }

        Or wrap your assertion using 'withMacroTesting', e.g. in 'invokeTest':

            class StringifyMacroTests: XCTestCase {
              override func invokeTest() {
                withMacroTesting(macros: ["stringify": StringifyMacro.self]) {
                  super.invokeTest()
                }
              }
              …
            }
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return
    }
    do {
      var origSourceFile = Parser.parse(source: try originalSource())
      if let foldedSourceFile = try OperatorTable.standardOperators.foldAll(origSourceFile).as(
        SourceFileSyntax.self
      ) {
        origSourceFile = foldedSourceFile
      }

      let origDiagnostics = ParseDiagnosticsGenerator.diagnostics(for: origSourceFile)
      let indentationWidth =
        indentationWidth
        ?? MacroTestingConfiguration.current.indentationWidth
        ?? Trivia(
          stringLiteral: String(
            SourceLocationConverter(fileName: "-", tree: origSourceFile).sourceLines
              .first(where: { $0.first?.isWhitespace == true && $0 != "\n" })?
              .prefix(while: { $0.isWhitespace })
              ?? "    "
          )
        )

      var context = BasicMacroExpansionContext(
        sourceFiles: [
          origSourceFile: .init(moduleName: "TestModule", fullFilePath: "Test.swift")
        ]
      )
      #if canImport(SwiftSyntax600)
        var expandedSourceFile = origSourceFile.expand(
          macros: macros,
          contextGenerator: { syntax in
            BasicMacroExpansionContext(
              sharingWith: context,
              lexicalContext: syntax.allMacroLexicalContexts()
            )
          },
          indentationWidth: indentationWidth
        )
      #else
        var expandedSourceFile = origSourceFile.expand(
          macros: macros,
          in: context,
          indentationWidth: indentationWidth
        )
      #endif

      var offset = 0

      func anchor(_ diag: Diagnostic) -> Diagnostic {
        let location = context.location(for: diag.position, anchoredAt: diag.node, fileName: "")
        return Diagnostic(
          node: diag.node,
          position: AbsolutePosition(utf8Offset: location.offset),
          message: diag.diagMessage,
          highlights: diag.highlights,
          notes: diag.notes,
          fixIts: diag.fixIts
        )
      }

      var allDiagnostics: [Diagnostic] { origDiagnostics + context.diagnostics }
      if !allDiagnostics.isEmpty || diagnosedSource != nil {
        offset += 1

        let converter = SourceLocationConverter(fileName: "-", tree: origSourceFile)
        let lineCount = converter.location(for: origSourceFile.endPosition).line
        let diagnostics =
          DiagnosticsFormatter
          .annotatedSource(
            tree: origSourceFile,
            diags: allDiagnostics.map(anchor),
            context: context,
            contextSize: lineCount
          )
          .description
          .replacingOccurrences(of: #"(^|\n) *\d* +│ "#, with: "$1", options: .regularExpression)
          .trimmingCharacters(in: .newlines)

        assertInlineSnapshot(
          of: diagnostics,
          as: ._lines,
          message: """
            Diagnostic output (\(newPrefix)) differed from expected output (\(oldPrefix)). \
            Difference: …
            """,
          syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
            deprecatedTrailingClosureLabels: ["matches"],
            trailingClosureLabel: "diagnostics",
            trailingClosureOffset: offset
          ),
          matches: diagnosedSource,
          fileID: fileID,
          file: filePath,
          function: function,
          line: line,
          column: column
        )
      } else if diagnosedSource != nil {
        offset += 1
        assertInlineSnapshot(
          of: nil,
          as: ._lines,
          message: """
            Diagnostic output (\(newPrefix)) differed from expected output (\(oldPrefix)). \
            Difference: …
            """,
          syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
            deprecatedTrailingClosureLabels: ["matches"],
            trailingClosureLabel: "diagnostics",
            trailingClosureOffset: offset
          ),
          matches: diagnosedSource,
          fileID: fileID,
          file: filePath,
          function: function,
          line: line,
          column: column
        )
      }

      if !allDiagnostics.isEmpty && allDiagnostics.allSatisfy({ !$0.fixIts.isEmpty }) {
        offset += 1

        let edits =
          context.diagnostics
          .flatMap(\.fixIts)
          .flatMap { $0.changes }
          .map { $0.edit(in: context) }

        var fixedSourceFile = origSourceFile
        fixedSourceFile = Parser.parse(
          source: FixItApplier.apply(
            edits: edits,
            to: origSourceFile
          )
          .description
        )
        if let foldedSourceFile = try OperatorTable.standardOperators.foldAll(fixedSourceFile).as(
          SourceFileSyntax.self
        ) {
          fixedSourceFile = foldedSourceFile
        }

        assertInlineSnapshot(
          of: fixedSourceFile.description.trimmingCharacters(in: .newlines),
          as: ._lines,
          message: """
            Fixed output (\(newPrefix)) differed from expected output (\(oldPrefix)). \
            Difference: …
            """,
          syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
            trailingClosureLabel: "fixes",
            trailingClosureOffset: offset
          ),
          matches: fixedSource,
          fileID: fileID,
          file: filePath,
          function: function,
          line: line,
          column: column
        )

        context = BasicMacroExpansionContext(
          sourceFiles: [
            fixedSourceFile: .init(moduleName: "TestModule", fullFilePath: "Test.swift")
          ]
        )
        #if canImport(SwiftSyntax600)
          expandedSourceFile = fixedSourceFile.expand(
            macros: macros,
            contextGenerator: { _ in context },
            indentationWidth: indentationWidth
          )
        #else
          expandedSourceFile = fixedSourceFile.expand(
            macros: macros,
            in: context,
            indentationWidth: indentationWidth
          )
        #endif
      } else if fixedSource != nil {
        offset += 1
        assertInlineSnapshot(
          of: nil,
          as: ._lines,
          message: """
            Fixed output (\(newPrefix)) differed from expected output (\(oldPrefix)). \
            Difference: …
            """,
          syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
            trailingClosureLabel: "fixes",
            trailingClosureOffset: offset
          ),
          matches: fixedSource,
          fileID: fileID,
          file: filePath,
          function: function,
          line: line,
          column: column
        )
      }

      if allDiagnostics.filter({ $0.diagMessage.severity == .error }).isEmpty {
        offset += 1
        assertInlineSnapshot(
          of: expandedSourceFile.description.trimmingCharacters(in: .newlines),
          as: ._lines,
          message: """
            Expanded output (\(newPrefix)) differed from expected output (\(oldPrefix)). \
            Difference: …
            """,
          syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
            deprecatedTrailingClosureLabels: ["matches"],
            trailingClosureLabel: "expansion",
            trailingClosureOffset: offset
          ),
          matches: expandedSource,
          fileID: fileID,
          file: filePath,
          function: function,
          line: line,
          column: column
        )
      } else if expandedSource != nil {
        offset += 1
        assertInlineSnapshot(
          of: nil,
          as: ._lines,
          message: """
            Expanded output (\(newPrefix)) differed from expected output (\(oldPrefix)). \
            Difference: …
            """,
          syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
            deprecatedTrailingClosureLabels: ["matches"],
            trailingClosureLabel: "expansion",
            trailingClosureOffset: offset
          ),
          matches: expandedSource,
          fileID: fileID,
          file: filePath,
          function: function,
          line: line,
          column: column
        )
      }
    } catch {
      recordIssue(
        "Threw error: \(error)",
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
  }
}

// From: https://github.com/apple/swift-syntax/blob/d647052/Sources/SwiftSyntaxMacrosTestSupport/Assertions.swift
extension FixIt.Change {
  /// Returns the edit for this change, translating positions from detached nodes
  /// to the corresponding locations in the original source file based on
  /// `expansionContext`.
  ///
  /// - SeeAlso: `FixIt.Change.edit`
  fileprivate func edit(in expansionContext: BasicMacroExpansionContext) -> SourceEdit {
    switch self {
    case .replace(let oldNode, let newNode):
      let start = expansionContext.position(of: oldNode.position, anchoredAt: oldNode)
      let end = expansionContext.position(of: oldNode.endPosition, anchoredAt: oldNode)
      return SourceEdit(
        range: start..<end,
        replacement: newNode.description
      )

    case .replaceLeadingTrivia(let token, let newTrivia):
      let start = expansionContext.position(of: token.position, anchoredAt: token)
      let end = expansionContext.position(
        of: token.positionAfterSkippingLeadingTrivia,
        anchoredAt: token
      )
      return SourceEdit(
        range: start..<end,
        replacement: newTrivia.description
      )

    case .replaceTrailingTrivia(let token, let newTrivia):
      let start = expansionContext.position(
        of: token.endPositionBeforeTrailingTrivia,
        anchoredAt: token
      )
      let end = expansionContext.position(of: token.endPosition, anchoredAt: token)
      return SourceEdit(
        range: start..<end,
        replacement: newTrivia.description
      )

    #if canImport(SwiftSyntax601)
      case .replaceChild(let replacingChildData):
        let range = replacingChildData.replacementRange
        let start = expansionContext.position(
          of: range.lowerBound,
          anchoredAt: replacingChildData.parent
        )
        let end = expansionContext.position(
          of: range.upperBound,
          anchoredAt: replacingChildData.parent
        )
        return SourceEdit(
          range: start..<end,
          replacement: replacingChildData.newChild.description
        )
      @unknown default:
        fatalError()
    #endif
    }
  }
}

// From: https://github.com/apple/swift-syntax/blob/d647052/Sources/SwiftSyntaxMacrosTestSupport/Assertions.swift
extension BasicMacroExpansionContext {
  /// Translates a position from a detached node to the corresponding position
  /// in the original source file.
  fileprivate func position(
    of position: AbsolutePosition,
    anchoredAt node: some SyntaxProtocol
  ) -> AbsolutePosition {
    let location = self.location(for: position, anchoredAt: Syntax(node), fileName: "")
    return AbsolutePosition(utf8Offset: location.offset)
  }
}

/// Asserts that a given Swift source string matches an expected string with all macros expanded.
///
/// See ``assertMacro(_:indentationWidth:record:of:diagnostics:fixes:expansion:fileID:file:function:line:column:)-90l38``
/// for more details.
///
/// - Parameters:
///   - macros: The macros to expand in the original source string. Required, either implicitly via
///     ``withMacroTesting(indentationWidth:record:macros:operation:)-7cm1s``, or explicitly
///     via this parameter.
///   - indentationWidth: The `Trivia` for setting indentation during macro expansion
///     (e.g., `.spaces(2)`). Defaults to the original source's indentation if unspecified. If the
///     original source lacks indentation, it defaults to `.spaces(4)`.
///   - record: The recording strategy to use. If not provided, it defaults to the current
///     configuration, which can be set using the `SNAPSHOT_TESTING_RECORD` environment variable.
///   - originalSource: A string of Swift source code.
///   - diagnosedSource: Swift source code annotated with expected diagnostics.
///   - fixedSource: Swift source code with expected fix-its applied.
///   - expandedSource: Expected Swift source string with macros expanded.
///   - fileID: The file ID where the assertion occurs.
///   - filePath: The file where the assertion occurs. The default is the filename of the test case
///     where you call this function.
///   - function: The function where the assertion occurs. The default is the name of the test
///     method where you call this function.
///   - line: The line where the assertion occurs. The default is the line number where you call
///     this function.
///   - column: The column where the assertion occurs. The default is the column where you call this
///     function.
public func assertMacro(
  _ macros: [Macro.Type],
  indentationWidth: Trivia? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  of originalSource: () throws -> String,
  diagnostics diagnosedSource: (() -> String)? = nil,
  fixes fixedSource: (() -> String)? = nil,
  expansion expandedSource: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  assertMacro(
    Dictionary(macros: macros),
    indentationWidth: indentationWidth,
    record: record,
    of: originalSource,
    diagnostics: diagnosedSource,
    fixes: fixedSource,
    expansion: expandedSource,
    fileID: fileID,
    file: filePath,
    function: function,
    line: line,
    column: column
  )
}

/// Customizes `assertMacro` for the duration of an operation.
///
/// Use this operation to customize how the `assertMacro` behaves in a test. It is most convenient
/// to use this tool to wrap `invokeTest` in a `XCTestCase` subclass so that the configuration
/// applies to every test method.
///
/// For example, to specify which macros will be expanded during an assertion for an entire test
/// case you can do the following:
///
/// ```swift
/// class StringifyTests: XCTestCase {
///   override func invokeTest() {
///     withMacroTesting(macros: [StringifyMacro.self]) {
///       super.invokeTest()
///     }
///   }
/// }
/// ```
///
/// And to re-record all macro expansions in a test case you can do the following:
///
/// ```swift
/// class StringifyTests: XCTestCase {
///   override func invokeTest() {
///     withMacroTesting(record: .all, macros: [StringifyMacro.self]) {
///       super.invokeTest()
///     }
///   }
/// }
/// ```
///
/// - Parameters:
///   - indentationWidth: The `Trivia` for setting indentation during macro expansion
///     (e.g., `.spaces(2)`). Defaults to the original source's indentation if unspecified. If the
///     original source lacks indentation, it defaults to `.spaces(4)`.
///   - record: The recording strategy to use for the macro expansion. If not provided, it defaults to the current
///     configuration, which can be set using the `SNAPSHOT_TESTING_RECORD` environment variable.
///   - macros: Specifies the macros to be expanded in the input Swift source string.
///   - operation: The operation to run with the configuration updated.
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  macros: [String: Macro.Type]? = nil,
  operation: () async throws -> R
) async rethrows -> R {
  var configuration = MacroTestingConfiguration.current
  if let indentationWidth { configuration.indentationWidth = indentationWidth }
  if let macros { configuration.macros = macros }
  return try await withSnapshotTesting(record: record) {
    try await MacroTestingConfiguration.$current.withValue(configuration) {
      try await operation()
    }
  }
}

/// Customizes `assertMacro` for the duration of an operation.
///
/// See ``withMacroTesting(indentationWidth:record:macros:operation:)-7cm1s`` for
/// more details.
///
/// - Parameters:
///   - indentationWidth: The `Trivia` for setting indentation during macro expansion
///     (e.g., `.spaces(2)`). Defaults to the original source's indentation if unspecified. If the
///     original source lacks indentation, it defaults to `.spaces(4)`.
///   - record: The recording strategy to use for the macro expansion. If not provided, it defaults to the current
///     configuration, which can be set using the `SNAPSHOT_TESTING_RECORD` environment variable.
///   - macros: Specifies the macros to be expanded in the input Swift source string.
///   - operation: The operation to run with the configuration updated.
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  macros: [String: Macro.Type]? = nil,
  operation: () throws -> R
) rethrows -> R {
  var configuration = MacroTestingConfiguration.current
  if let indentationWidth { configuration.indentationWidth = indentationWidth }
  if let macros { configuration.macros = macros }
  return try withSnapshotTesting(record: record) {
    try MacroTestingConfiguration.$current.withValue(configuration) {
      try operation()
    }
  }
}

/// Customizes `assertMacro` for the duration of an operation.
///
/// See ``assertMacro(_:indentationWidth:record:of:diagnostics:fixes:expansion:fileID:file:function:line:column:)-90l38``
/// for more details.
///
/// - Parameters:
///   - indentationWidth: The `Trivia` for setting indentation during macro expansion
///     (e.g., `.spaces(2)`). Defaults to the original source's indentation if unspecified. If the
///     original source lacks indentation, it defaults to `.spaces(4)`.
///   - record: The recording strategy to use for the macro expansion. If not provided, it defaults to the current
///     configuration, which can be set using the `SNAPSHOT_TESTING_RECORD` environment variable.
///   - macros: Specifies the macros to be expanded in the input Swift source string.
///   - operation: The operation to run with the configuration updated.
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  macros: [Macro.Type],
  operation: () async throws -> R
) async rethrows -> R {
  try await withMacroTesting(
    indentationWidth: indentationWidth,
    record: record,
    macros: Dictionary(macros: macros),
    operation: operation
  )
}

/// Customizes `assertMacro` for the duration of an operation.
///
/// See ``withMacroTesting(indentationWidth:record:macros:operation:)-7cm1s`` for
/// more details.
///
/// - Parameters:
///   - indentationWidth: The `Trivia` for setting indentation during macro expansion
///     (e.g., `.spaces(2)`). Defaults to the original source's indentation if unspecified. If the
///     original source lacks indentation, it defaults to `.spaces(4)`.
///   - record: The recording strategy to use for the macro expansion. If not provided, it defaults to the current
///     configuration, which can be set using the `SNAPSHOT_TESTING_RECORD` environment variable
///   - macros: Specifies the macros to be expanded in the input Swift source string.
///   - operation: The operation to run with the configuration updated.
public func withMacroTesting<R>(
  indentationWidth: Trivia? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  macros: [Macro.Type],
  operation: () throws -> R
) rethrows -> R {
  try withMacroTesting(
    indentationWidth: indentationWidth,
    record: record,
    macros: Dictionary(macros: macros),
    operation: operation
  )
}

extension Snapshotting where Value == String, Format == String {
  fileprivate static let _lines = Snapshotting(
    pathExtension: "txt",
    diffing: Diffing(
      toData: { Data($0.utf8) },
      fromData: { String(decoding: $0, as: UTF8.self) }
    ) { old, new in
      guard old != new else { return nil }

      let newLines = new.split(separator: "\n", omittingEmptySubsequences: false)

      let oldLines = old.split(separator: "\n", omittingEmptySubsequences: false)
      let difference = newLines.difference(from: oldLines)

      var result = ""

      var insertions = [Int: Substring]()
      var removals = [Int: Substring]()

      for change in difference {
        switch change {
        case let .insert(offset, element, _):
          insertions[offset] = element
        case let .remove(offset, element, _):
          removals[offset] = element
        }
      }

      var oldLine = 0
      var newLine = 0

      while oldLine < oldLines.count || newLine < newLines.count {
        if let removal = removals[oldLine] {
          result += "\(oldPrefix) \(removal)\n"
          oldLine += 1
        } else if let insertion = insertions[newLine] {
          result += "\(newPrefix) \(insertion)\n"
          newLine += 1
        } else {
          result += "\(prefix) \(oldLines[oldLine])\n"
          oldLine += 1
          newLine += 1
        }
      }

      let attachment = XCTAttachment(
        data: Data(result.utf8),
        uniformTypeIdentifier: "public.patch-file"
      )
      return (result, [attachment])
    }
  )
}

internal func macroName(className: String, isExpression: Bool) -> String {
  var name =
    className
    .replacingOccurrences(of: "Macro$", with: "", options: .regularExpression)
  if !name.isEmpty, isExpression {
    var prefix = name.prefix(while: \.isUppercase)
    if prefix.count > 1, name[prefix.endIndex...].first?.isLowercase == true {
      prefix.removeLast()
    }
    name.replaceSubrange(prefix.startIndex..<prefix.endIndex, with: prefix.lowercased())
  }
  return name
}

struct MacroTestingConfiguration {
  @TaskLocal static var current = Self()

  var indentationWidth: Trivia? = nil
  var macros: [String: Macro.Type]?
}

extension Dictionary where Key == String, Value == Macro.Type {
  init(macros: [Macro.Type]) {
    self.init(
      macros.map {
        let name = macroName(
          className: String(describing: $0),
          isExpression: $0 is ExpressionMacro.Type
        )
        return (key: name, value: $0)
      },
      uniquingKeysWith: { _, rhs in rhs }
    )
  }
}

private let oldPrefix = "\u{2212}"
private let newPrefix = "+"
private let prefix = "\u{2007}"
