import MacroTesting
import XCTest

final class StringifyMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [StringifyMacro.self]) {
      super.invokeTest()
    }
  }

  func testStringify() {
    assertMacro {
      #"""
      let x = 1
      let y = 2
      print(#stringify(x + y))
      """#
    } expansion: {
      """
      let x = 1
      let y = 2
      print((x + y, "x + y"))
      """
    }
  }
}
