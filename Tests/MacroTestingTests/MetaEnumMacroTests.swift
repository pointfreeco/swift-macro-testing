import MacroTesting
import XCTest

final class MetaEnumMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [MetaEnumMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionAddsNestedMetaEnum() {
    assertMacro {
      """
      @MetaEnum enum Cell {
        case integer(Int)
        case text(String)
        case boolean(Bool)
        case null
      }
      """
    } expansion: {
      """
      enum Cell {
        case integer(Int)
        case text(String)
        case boolean(Bool)
        case null

        enum Meta {
          case integer
          case text
          case boolean
          case null
          init(_ __macro_local_6parentfMu_: Cell) {
            switch __macro_local_6parentfMu_ {
            case .integer:
              self = .integer
            case .text:
              self = .text
            case .boolean:
              self = .boolean
            case .null:
              self = .null
            }
          }
        }
      }
      """
    }
  }

  func testExpansionAddsPublicNestedMetaEnum() {
    assertMacro {
      """
      @MetaEnum public enum Cell {
        case integer(Int)
        case text(String)
        case boolean(Bool)
      }
      """
    } expansion: {
      """
      public enum Cell {
        case integer(Int)
        case text(String)
        case boolean(Bool)

        public enum Meta {
          case integer
          case text
          case boolean
          public init(_ __macro_local_6parentfMu_: Cell) {
            switch __macro_local_6parentfMu_ {
            case .integer:
              self = .integer
            case .text:
              self = .text
            case .boolean:
              self = .boolean
            }
          }
        }
      }
      """
    }
  }

  func testExpansionOnStructEmitsError() {
    assertMacro {
      """
      @MetaEnum struct Cell {
        let integer: Int
        let text: String
        let boolean: Bool
      }
      """
    } diagnostics: {
      """
      @MetaEnum struct Cell {
      ┬────────
      ╰─ 🛑 '@MetaEnum' can only be attached to an enum, not a struct
        let integer: Int
        let text: String
        let boolean: Bool
      }
      """
    }
  }
}
