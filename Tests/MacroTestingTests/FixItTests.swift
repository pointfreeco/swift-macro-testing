import MacroTesting
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import XCTest

private enum ReplaceFirstMemberMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      let nodeToReplace = declaration.memberBlock.members.first,
      let newNode = try? MemberBlockItemSyntax(
        decl: VariableDeclSyntax(SyntaxNodeString(stringLiteral: "\n  let oye: Oye"))
      )
    else { return [] }

    context.diagnose(
      Diagnostic(
        node: node.attributeName,
        message: SimpleDiagnosticMessage(
          message: "First member needs to be replaced",
          diagnosticID: MessageID(domain: "domain", id: "diagnostic2"),
          severity: .warning
        ),
        fixIts: [
          FixIt(
            message: SimpleDiagnosticMessage(
              message: "Replace the first member",
              diagnosticID: MessageID(domain: "domain", id: "fixit1"),
              severity: .error
            ),
            changes: [
              .replace(oldNode: Syntax(nodeToReplace), newNode: Syntax(newNode))
            ]
          )
        ]
      )
    )

    return []
  }
}

final class FixItTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [ReplaceFirstMemberMacro.self]) {
      super.invokeTest()
    }
  }

  func testReplaceFirstMember() {
    assertMacro {
      """
      @ReplaceFirstMember
      struct FooBar {
        let foo: Foo
        let bar: Bar
        let baz: Baz
      }
      """
    } diagnostics: {
      """
      @ReplaceFirstMember
       ┬─────────────────
       ╰─ ⚠️ First member needs to be replaced
          ✏️ Replace the first member
      struct FooBar {
        let foo: Foo
        let bar: Bar
        let baz: Baz
      }
      """
    } fixes: {
      """
      @ReplaceFirstMember
      struct FooBar {
        let oye: Oye
        let bar: Bar
        let baz: Baz
      }
      """
    } expansion: {
      """
      struct FooBar {
        let oye: Oye
        let bar: Bar
        let baz: Baz
      }
      """
    }
  }
}
