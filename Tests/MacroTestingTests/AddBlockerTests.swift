import MacroTesting
import XCTest

final class AddBlockerTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [AddBlocker.self]) {
      super.invokeTest()
    }
  }

  func testAddBlocker() {
    assertMacro {
      """
      let x = 1
      let y = 2
      let z = 3
      #addBlocker(x * y + z)
      """
    } diagnostics: {
      """
      let x = 1
      let y = 2
      let z = 3
      #addBlocker(x * y + z)
                  ───── ┬ ─
                        ╰─ ⚠️ blocked an add; did you mean to subtract?
                           ✏️ use '-'
      """
    } fixes: {
      """
      let x = 1
      let y = 2
      let z = 3
      #addBlocker(x * y - z)
      """
    } expansion: {
      """
      let x = 1
      let y = 2
      let z = 3
      x * y - z
      """
    }
  }

  func testAddBlocker_Inline() {
    assertMacro {
      """
      #addBlocker(1 * 2 + 3)
      """
    } diagnostics: {
      """
      #addBlocker(1 * 2 + 3)
                  ───── ┬ ─
                        ╰─ ⚠️ blocked an add; did you mean to subtract?
                           ✏️ use '-'
      """
    } fixes: {
      """
      #addBlocker(1 * 2 - 3)
      """
    } expansion: {
      """
      1 * 2 - 3
      """
    }
  }
}
