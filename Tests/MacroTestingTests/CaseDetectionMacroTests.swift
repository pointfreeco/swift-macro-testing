import MacroTesting
import XCTest

final class CaseDetectionMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [CaseDetectionMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionAddsComputedProperties() {
    assertMacro {
      """
      @CaseDetection
      enum Animal {
        case dog
        case cat(curious: Bool)
      }
      """
    } expansion: {
      """
      enum Animal {
        case dog
        case cat(curious: Bool)

        var isDog: Bool {
          if case .dog = self {
            return true
          }

          return false
        }

        var isCat: Bool {
          if case .cat = self {
            return true
          }

          return false
        }
      }
      """
    }
  }
}
