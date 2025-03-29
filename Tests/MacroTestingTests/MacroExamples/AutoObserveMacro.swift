import SwiftSyntax
import SwiftSyntaxMacros

public enum AutoObserveMacro: BodyMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    guard
      let functionDecl = declaration.as(FunctionDeclSyntax.self),
      let body = functionDecl.body
    else {
      throw CustomError.message("Expected a function declaration with a body.")
    }

    let rewriter = ObserveOperatorRewriter()
    let newBody = rewriter.rewrite(body).as(CodeBlockSyntax.self)!
    if let error = rewriter.error {
      throw error
    }
    return Array(newBody.statements)
  }
}

final class ObserveOperatorRewriter: SyntaxRewriter {
  var error: (any Error)? = nil

  override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    guard node.operator.trimmedDescription == "<~" else {
      return ExprSyntax(node)
    }
    var assignment = node
    assignment.operator = ExprSyntax(
      DeclReferenceExprSyntax(baseName: TokenSyntax.equalToken(leadingTrivia: .space, trailingTrivia: .space))
    )
    return """
    observe { [weak self] in
      guard let self = self else { return }
      \(raw: assignment)
    }
    """
  }
}
