import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public enum EmptyParenthesisHighlightsMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard case .argumentList(let arguments) = node.arguments, arguments.isEmpty else { return [] }
    throw DiagnosticsError(diagnostics: [.init(
      node: arguments,
      message: SimpleDiagnosticMessage(
        message: "It either takes no parameters or all parameters have default values, so the parenthesis can be omitted",
        diagnosticID: MessageID(domain: "domain", id: "diagnosticEmptyParenthesis"),
        severity: .error
      ),
      highlights: [node.leftParen.map(Syntax.init)!, node.rightParen.map(Syntax.init)!]
    )])
  }
}
