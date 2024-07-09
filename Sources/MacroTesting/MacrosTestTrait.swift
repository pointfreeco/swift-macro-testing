#if canImport(Testing)
  import SnapshotTesting
  import SwiftSyntax
  import SwiftSyntaxMacros
  @_spi(Experimental) import Testing

  @_spi(Experimental)
  extension Trait where Self == _MacrosTestTrait {
    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameters:
    ///   - record: The record mode of the test.
    ///   - diffTool: The diff tool to use in failure messages.
    public static func macros(
      indentationWidth: Trivia? = nil,
      record: SnapshotTestingConfiguration.Record? = nil,
      macros: [String: Macro.Type]? = nil
    ) -> Self {
      _MacrosTestTrait(
        configuration: MacroTestingConfiguration(
          indentationWidth: indentationWidth,
          macros: macros
        ),
        record: record
      )
    }
  }

  /// A type representing the configuration of snapshot testing.
  @_spi(Experimental)
  public struct _MacrosTestTrait: CustomExecutionTrait, SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: MacroTestingConfiguration
    let record: SnapshotTestingConfiguration.Record?

    public func execute(
      _ function: @escaping () async throws -> Void,
      for test: Test,
      testCase: Test.Case?
    ) async throws {
      try await withMacroTesting(
        indentationWidth: configuration.indentationWidth,
        macros: configuration.macros
      ) {
        try await withSnapshotTesting(record: record) {
          try await function()
        }
      }
    }
  }
#endif
