import MacroTesting
import XCTest

final class EntryMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      macros: [
        EntryMacro.self
      ]
    ) {
      super.invokeTest()
    }
  }

  func testWithinEnvironmentValues() {
    assertMacro {
      """
      extension EnvironmentValues {
        @Entry var x: String = ""
      }
      """
    } expansion: {
      """
      extension EnvironmentValues {
        var x: String {
          get {
            fatalError()
          }
        }
      }
      """
    }
  }

  func testNotWithinEnvironmentValues() {
    assertMacro {
      """
      extension String {
        @Entry var x: String = ""
      }
      """
    } diagnostics: {
      """
      extension String {
        @Entry var x: String = ""
        ┬─────
        ╰─ 🛑 '@Entry' macro can only attach to var declarations inside extensions of EnvironmentValues
      }
      """
    }
  }
}
