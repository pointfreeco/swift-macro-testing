import MacroTesting
import XCTest

final class CustomCodableMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [CodableKey.self, CustomCodable.self]) {
      super.invokeTest()
    }
  }

  func testExpansionAddsDefaultCodingKeys() {
    assertMacro {
      """
      @CustomCodable
      struct Person {
        let name: String
        let age: Int
      }
      """
    } expansion: {
      """
      struct Person {
        let name: String
        let age: Int

        enum CodingKeys: String, CodingKey {
          case name
          case age
        }
      }
      """
    }
  }

  func testExpansionWithCodableKeyAddsCustomCodingKeys() {
    assertMacro {
      """
      @CustomCodable
      struct Person {
        let name: String
        @CodableKey("user_age") let age: Int

        func randomFunction() {}
      }
      """
    } expansion: {
      """
      struct Person {
        let name: String
        let age: Int

        func randomFunction() {}

        enum CodingKeys: String, CodingKey {
          case name
          case age = "user_age"
        }
      }
      """
    }
  }
}
