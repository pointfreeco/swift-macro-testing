import MacroTesting
import XCTest

final class StringifyMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [StringifyMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionWithBasicArithmeticExpression() {
    assertMacro {
      """
      let a = #stringify(x + y)
      """
    } expansion: {
      """
      let a = (x + y, "x + y")
      """
    }
  }

  func testExpansionWithStringInterpolation() {
    assertMacro {
      #"""
      let b = #stringify("Hello, \(name)")
      """#
    } expansion: {
      #"""
      let b = ("Hello, \(name)", #""Hello, \(name)""#)
      """#
    }
  }
}
