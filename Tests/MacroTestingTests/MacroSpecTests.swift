#if canImport(SwiftSyntax600)
  import MacroTesting
  import SwiftSyntax
  import SwiftSyntaxMacroExpansion
  import SwiftSyntaxMacros
  import XCTest

  final class MacroSpecTests: BaseTestCase {
    override func invokeTest() {
      withMacroTesting(
        macros: [
          "AutoEquatable": MacroSpec(
            type: ConformanceProvidingMacro.self,
            conformances: ["Equatable"]
          )
        ]
      ) {
        super.invokeTest()
      }
    }

    func testConformancesArePassedToExtensionMacro() {
      assertMacro {
        """
        @AutoEquatable
        struct User {
          let name: String
        }
        """
      } expansion: {
        """
        struct User {
          let name: String
        }

        extension User: Equatable {
        }
        """
      }
    }

    func testAssertMacroWithSpecs() {
      assertMacro(
        [
          "AutoConformances": MacroSpec(
            type: ConformanceProvidingMacro.self,
            conformances: ["Equatable", "Hashable", "Sendable"]
          )
        ]
      ) {
        """
        @AutoConformances
        struct User {
          let name: String
        }
        """
      } expansion: {
        """
        struct User {
          let name: String
        }

        extension User: Equatable, Hashable, Sendable {
        }
        """
      }
    }
  }

  private enum ConformanceProvidingMacro: ExtensionMacro {
    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
      guard !protocols.isEmpty else { return [] }
      let conformances = protocols.map(\.trimmedDescription).joined(separator: ", ")
      return [
        try ExtensionDeclSyntax("extension \(type.trimmed): \(raw: conformances) {}")
      ]
    }
  }

  #if canImport(Testing) && compiler(>=6)
    import Testing

    @Suite(
      .macros(
        [
          "AutoEquatable": MacroSpec(
            type: ConformanceProvidingMacro.self,
            conformances: ["Equatable"]
          )
        ],
        record: .missing
      )
    )
    struct MacroSpecSwiftTestingTests {
      @Test
      func conformancesArePassedToExtensionMacro() {
        assertMacro {
          """
          @AutoEquatable
          struct User {
            let name: String
          }
          """
        } expansion: {
          """
          struct User {
            let name: String
          }

          extension User: Equatable {
          }
          """
        }
      }
    }
  #endif
#endif
