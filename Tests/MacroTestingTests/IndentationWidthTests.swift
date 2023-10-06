import MacroTesting
import SwiftSyntax
import SwiftSyntaxMacros
import XCTest

private struct AddMemberMacro: MemberMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    return ["let v: T"]
  }
}

final class IndentationWidthTests: XCTestCase {
  func testExpansionAddsMemberUsingDetectedIndentation() {
    assertMacro([AddMemberMacro.self]) {
      """
      @AddMember
      struct S {
        let w: T
      }
      """
    } expansion: {
      """
      struct S {
        let w: T

        let v: T
      }
      """
    }
  }

  func testExpansionAddsMemberToEmptyStructUsingDefaultIndentation() {
    assertMacro([AddMemberMacro.self]) {
      """
      @AddMember
      struct S {
      }
      """
    } expansion: {
      """
      struct S {

          let v: T
      }
      """
    }
  }

  func testExpansionAddsMemberToEmptyStructUsingTwoSpaceIndentation() {
    assertMacro(
      [AddMemberMacro.self],
      indentationWidth: .spaces(2)
    ) {
      """
      @AddMember
      struct S {
      }
      """
    } expansion: {
      """
      struct S {

        let v: T
      }
      """
    }
  }

  func testExpansionAddsMemberToEmptyStructUsingTwoSpaceIndentation_withMacroTesting() {
    withMacroTesting(
      indentationWidth: .spaces(2),
      macros: [AddMemberMacro.self]
    ) {
      assertMacro {
        """
        @AddMember
        struct S {
        }
        """
      } expansion: {
        """
        struct S {

          let v: T
        }
        """
      }
    }
  }

  func testExpansionAddsMemberUsingMistchedIndentation() {
    assertMacro(
      [AddMemberMacro.self],
      indentationWidth: .spaces(4)
    ) {
      """
      @AddMember
      struct S {
        let w: T
      }
      """
    } expansion: {
      """
      struct S {
        let w: T

          let v: T
      }
      """
    }
  }
}
