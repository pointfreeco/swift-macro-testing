import MacroTesting
import XCTest

final class WrapStoredPropertiesMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: ["wrapStoredProperties": WrapStoredPropertiesMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionAddsPublished() {
    assertMacro {
      """
      @wrapStoredProperties("Published")
      struct Test {
        var value: Int
      }
      """
    } expansion: {
      """
      struct Test {
        @Published
        var value: Int
      }
      """
    }
  }

  func testExpansionAddsDeprecationAttribute() {
    assertMacro {
      """
      @wrapStoredProperties(#"available(*, deprecated, message: "hands off my data")"#)
      struct Test {
        var value: Int
      }
      """
    } expansion: {
      """
      struct Test {
        @available(*, deprecated, message: "hands off my data")
        var value: Int
      }
      """
    }
  }

  func testExpansionIgnoresComputedProperty() {
    assertMacro {
      """
      @wrapStoredProperties("Published")
      struct Test {
        var value: Int {
          get { return 0 }
          set {}
        }
      }
      """
    } expansion: {
      """
      struct Test {
        var value: Int {
          get { return 0 }
          set {}
        }
      }
      """
    }
  }

  func testExpansionWithInvalidAttributeEmitsError() {
    assertMacro {
      """
      @wrapStoredProperties(12)
      struct Test {
        var value: Int
      }
      """
    } diagnostics: {
      """
      @wrapStoredProperties(12)
      ┬────────────────────────
      ╰─ 🛑 macro requires a string literal containing the name of an attribute
      struct Test {
        var value: Int
      }
      """
    }
  }
}
