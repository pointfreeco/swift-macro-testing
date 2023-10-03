import MacroTesting
import XCTest

final class EquatableExtensionMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(macros: ["equatable": EquatableExtensionMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionAddsExtensionWithEquatableConformance() {
    assertMacro {
      """
      @equatable
      final public class Message {
        let text: String
        let sender: String
      }
      """
    } expansion: {
      """
      final public class Message {
        let text: String
        let sender: String
      }

      extension Message: Equatable {
      }
      """
    }
  }
}
