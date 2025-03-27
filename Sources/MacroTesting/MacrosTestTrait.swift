#if canImport(Testing) && compiler(>=6)
  import SnapshotTesting
  import SwiftSyntax
  import SwiftSyntaxMacros
  import Testing

  /// A type representing the configuration of snapshot testing.
  @_documentation(visibility: private)
  public struct _MacrosTestTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: MacroTestingConfiguration
    let record: SnapshotTestingConfiguration.Record?
  }

  extension Trait where Self == _MacrosTestTrait {
    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameters:
    ///   - indentationWidth: The `Trivia` for setting indentation during macro expansion (e.g., `.spaces(2)`).
    ///     Defaults to the original source's indentation if unspecified.
    ///   - record: The recording strategy to use for macro expansions. This can be set to `.all`, `.missing`,
    ///     `.never`, or `.failed`. If not provided, it uses the current configuration, which can also be set via
    ///     the `SNAPSHOT_TESTING_RECORD` environment variable.
    ///   - macros: A dictionary mapping macro names to their implementations. This specifies which macros
    ///     should be expanded during testing.
    public static func macros(
      _ macros: [String: Macro.Type]? = nil,
      indentationWidth: Trivia? = nil,
      record: SnapshotTestingConfiguration.Record? = nil
    ) -> Self {
      _MacrosTestTrait(
        configuration: MacroTestingConfiguration(
          indentationWidth: indentationWidth,
          macros: macros
        ),
        record: record
      )
    }

    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameters:
    ///   - indentationWidth: The `Trivia` for setting indentation during macro expansion (e.g., `.spaces(2)`).
    ///     Defaults to the original source's indentation if unspecified.
    ///   - record: The recording strategy to use for macro expansions. This can be set to `.all`, `.missing`,
    ///     `.never`, or `.failed`. If not provided, it uses the current configuration, which can also be set via
    ///     the `SNAPSHOT_TESTING_RECORD` environment variable.
    ///   - macros: An array of macros. This specifies which macros should be expanded during testing.
    public static func macros(
      _ macros: [Macro.Type]? = nil,
      indentationWidth: Trivia? = nil,
      record: SnapshotTestingConfiguration.Record? = nil
    ) -> Self {
      _MacrosTestTrait(
        configuration: MacroTestingConfiguration(
          indentationWidth: indentationWidth,
          macros: macros.map { Dictionary(macros: $0) }
        ),
        record: record
      )
    }
  }

  #if swift(>=6.1)
    @_documentation(visibility: private)
    extension _MacrosTestTrait: TestScoping {
      public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
      ) async throws {
        try await MacroTestingConfiguration.$current.withValue(configuration) {
          try await SnapshotTestingConfiguration.$current.withValue(
            SnapshotTestingConfiguration(record: record, diffTool: nil)
          ) {
            try await function()
          }
        }
      }
    }
  #else
    extension Test {
      var indentationWidth: Trivia? {
        for trait in traits.reversed() {
          if let indentationWidth = (trait as? _MacrosTestTrait)?.configuration.indentationWidth {
            return indentationWidth
          }
        }
        return nil
      }

      var macros: [String: Macro.Type]? {
        for trait in traits.reversed() {
          if let macros = (trait as? _MacrosTestTrait)?.configuration.macros {
            return macros
          }
        }
        return nil
      }

      var record: SnapshotTestingConfiguration.Record? {
        for trait in traits.reversed() {
          if let macros = (trait as? _MacrosTestTrait)?.record {
            return macros
          }
        }
        return nil
      }
    }
  #endif
#endif
