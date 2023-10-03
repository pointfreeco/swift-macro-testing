import MacroTesting
import XCTest

final class AddBlockerTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [AddBlocker.self]) {
      super.invokeTest()
    }
  }

  func testExpansionTransformsAdditionToSubtractionAndEmitsWarning() {
    assertMacro {
      """
      #addBlocker(x * y + z)
      """
    } diagnostics: {
      """
      #addBlocker(x * y + z)
                  ───── ┬ ─
                        ╰─ ⚠️ blocked an add; did you mean to subtract?
                           ✏️ use '-'
      """
    } fixes: {
      """
      #addBlocker(x * y - z)
      """
    } expansion: {
      """
      x * y - z
      """
    }
  }

  func testExpansionPreservesSubtraction() {
    assertMacro {
      """
      #addBlocker(x * y - z)
      """
    } expansion: {
      """
      x * y - z
      """
    }
  }
}
