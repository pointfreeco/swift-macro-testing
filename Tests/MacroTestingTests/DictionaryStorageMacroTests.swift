import MacroTesting
import XCTest

final class DictionaryStorageMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      macros: [
        DictionaryStorageMacro.self,
        DictionaryStoragePropertyMacro.self,
      ]
    ) {
      super.invokeTest()
    }
  }

  func testExpansionConvertsStoredProperties() {
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
        var x: Int {
          get {
            _storage["x", default: 1] as! Int
          }
          set {
            _storage["x"] = newValue
          }
        }
        var y: Int {
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

  func testExpansionIgnoresComputedProperties() {
    assertMacro {
      """
      @DictionaryStorage
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

        var _storage: [String: Any] = [:]
      }
      """
    }
  }
}
