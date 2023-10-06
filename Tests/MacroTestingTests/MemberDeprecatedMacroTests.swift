import MacroTesting
import XCTest

final class MemberDepreacatedMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(macros: ["memberDeprecated": MemberDeprecatedMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionMarksMembersAsDeprecated() {
    assertMacro {
      """
      @memberDeprecated
      public struct SomeStruct {
        typealias MacroName = String

        public var oldProperty: Int = 420

        func oldMethod() {
          print("This is an old method.")
        }
      }
      """
    } expansion: {
      """
      public struct SomeStruct {
        @available(*, deprecated)
        typealias MacroName = String
        @available(*, deprecated)

        public var oldProperty: Int = 420
        @available(*, deprecated)

        func oldMethod() {
          print("This is an old method.")
        }
      }
      """
    }
  }
}
