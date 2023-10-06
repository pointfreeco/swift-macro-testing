import MacroTesting
import XCTest

final class FuncUniqueMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      macros: [FuncUniqueMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testExpansionCreatesDeclarationWithUniqueFunction() {
    assertMacro {
      """
      #FuncUnique()
      """
    } expansion: {
      """
      class MyClass {
        func __macro_local_6uniquefMu_() {
        }
      }
      """
    }
  }
}
