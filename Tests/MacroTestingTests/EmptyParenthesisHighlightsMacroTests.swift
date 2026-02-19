import MacroTesting
import XCTest

final class EmptyParenthesisHighlightsMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [EmptyParenthesisHighlightsMacro.self]) {
      super.invokeTest()
    }
  }
  
  func testEmptyParenthesisHighlightsMacro() {
    assertMacro {
      #"""
      @EmptyParenthesisHighlights()
      struct Whatever {}
      """#
    } diagnostics: {
      """
      @EmptyParenthesisHighlights()
                                  ╰─ 🛑 It either takes no parameters or all parameters have default values, so the parenthesis can be omitted
      struct Whatever {}
      """
    }
  }
}
