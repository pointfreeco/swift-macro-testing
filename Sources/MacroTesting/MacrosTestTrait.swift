#if canImport(Testing)
  import SnapshotTesting
  import SwiftSyntax
  import SwiftSyntaxMacros
  import Testing

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
  public struct _MacrosTestTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: MacroTestingConfiguration
    let record: SnapshotTestingConfiguration.Record?
  }

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
