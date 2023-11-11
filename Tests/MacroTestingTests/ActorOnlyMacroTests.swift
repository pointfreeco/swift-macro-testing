import MacroTesting
import XCTest

final class ActorOnlyMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: ["ActorOnly": ActorOnlyMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionOnStruct() {
    assertMacro {
      """
      @ActorOnly
      struct MyStruct {

      }
      """
    } diagnostics: {
      """
      @ActorOnly
      ╰─ 🛑 'ActorOnly' macro can only be applied to an actor
         ✏️ Remove '@ActorOnly' attribute
      struct MyStruct {

      }
      """
    } fixes: {
      """
      struct MyStruct {

      }
      """
    } expansion: {
      """
      struct MyStruct {

      }
      """
    }
  }
}
