import SwiftSyntax
import SwiftSyntaxMacros

// Not complete, just enough to unit test lexical context.
public struct EntryMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    let isInEnvironmentValues = context.lexicalContext.contains { lexicalContext in
      lexicalContext.as(ExtensionDeclSyntax.self)?.extendedType.trimmedDescription
        == "EnvironmentValues"
    }

    guard isInEnvironmentValues else {
      throw MacroExpansionErrorMessage(
        "'@Entry' macro can only attach to var declarations inside extensions of EnvironmentValues")
    }

    return [
      AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
        "fatalError()"
      }
    ]
  }
}
