import MacroTesting
import XCTest

final class NewTypeMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [NewTypeMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionAddsStringRawType() {
    assertMacro {
      """
      @NewType(String.self)
      struct Username {
      }
      """
    } expansion: {
      """
      struct Username {

          typealias RawValue = String

          var rawValue: RawValue

          init(_ rawValue: RawValue) {
              self.rawValue = rawValue
          }
      }
      """
    }
  }

  func testExpansionWithPublicAddsPublicStringRawType() {
    assertMacro {
      """
      @NewType(String.self)
      public struct MyString {
      }
      """
    } expansion: {
      """
      public struct MyString {

          public typealias RawValue = String

          public var rawValue: RawValue

          public init(_ rawValue: RawValue) {
              self.rawValue = rawValue
          }
      }
      """
    }
  }

  func testExpansionOnClassEmitsError() {
    assertMacro {
      """
      @NewType(Int.self)
      class NotAUsername {
      }
      """
    } diagnostics: {
      """
      @NewType(Int.self)
      ┬─────────────────
      ╰─ 🛑 @NewType can only be applied to a struct declarations.
      class NotAUsername {
      }
      """
    }
  }

  func testExpansionWithMissingRawTypeEmitsError() {
    assertMacro {
      """
      @NewType
      struct NoRawType {
      }
      """
    } diagnostics: {
      """
      @NewType
      ┬───────
      ╰─ 🛑 @NewType requires the raw type as an argument, in the form "RawType.self".
      struct NoRawType {
      }
      """
    }
  }
}
