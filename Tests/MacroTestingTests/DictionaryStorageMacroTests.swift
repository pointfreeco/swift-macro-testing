import MacroTesting
import XCTest

final class DictionaryStorageMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [DictionaryStorageMacro.self]) {
      super.invokeTest()
    }
  }

  func testDictionaryStorage() {
    assertMacro {
      """
      @DictionaryStorage
      struct Point {
        var x: Int = 1
        var y: Int = 2
      }
      """
    } expansion: {
      """
      struct Point {
        var x: Int = 1 {
          get {
            _storage["x", default: 1] as! Int
          }
          set {
            _storage["x"] = newValue
          }
        }
        var y: Int = 2 {
          get {
            _storage["y", default: 2] as! Int
          }
          set {
            _storage["y"] = newValue
          }
        }

        var _storage: [String: Any] = [:]
      }
      """
    }
  }

  func testExpansionWithoutInitializersEmitsError() {
    assertMacro {
      """
      @DictionaryStorage
      class Point {
        let x: Int
        let y: Int
      }
      """
    } diagnostics: {
      """
      @DictionaryStorage
      class Point {
        let x: Int
        ╰─ 🛑 stored property must have an initializer
        let y: Int
        ╰─ 🛑 stored property must have an initializer
      }
      """
    }
  }
}
