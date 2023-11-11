import MacroTesting
import XCTest

final class OptionSetMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: ["MyOptionSet": OptionSetMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionOnStructWithNestedEnumAndStatics() {
    assertMacro {
      """
      @MyOptionSet<UInt8>
      struct ShippingOptions {
        private enum Options: Int {
          case nextDay
          case secondDay
          case priority
          case standard
        }

        static let express: ShippingOptions = [.nextDay, .secondDay]
        static let all: ShippingOptions = [.express, .priority, .standard]
      }
      """
    } expansion: {
      """
      struct ShippingOptions {
        private enum Options: Int {
          case nextDay
          case secondDay
          case priority
          case standard
        }

        static let express: ShippingOptions = [.nextDay, .secondDay]
        static let all: ShippingOptions = [.express, .priority, .standard]

        typealias RawValue = UInt8

        var rawValue: RawValue

        init() {
          self.rawValue = 0
        }

        init(rawValue: RawValue) {
          self.rawValue = rawValue
        }

        static let nextDay: Self =
          Self (rawValue: 1 << Options.nextDay.rawValue)

        static let secondDay: Self =
          Self (rawValue: 1 << Options.secondDay.rawValue)

        static let priority: Self =
          Self (rawValue: 1 << Options.priority.rawValue)

        static let standard: Self =
          Self (rawValue: 1 << Options.standard.rawValue)
      }

      extension ShippingOptions: OptionSet {
      }
      """
    }
  }

  func testExpansionOnPublicStructWithExplicitOptionSetConformance() {
    assertMacro {
      """
      @MyOptionSet<UInt8>
      public struct ShippingOptions: OptionSet {
        private enum Options: Int {
          case nextDay
          case standard
        }
      }
      """
    } expansion: {
      """
      public struct ShippingOptions: OptionSet {
        private enum Options: Int {
          case nextDay
          case standard
        }

        public typealias RawValue = UInt8

        public var rawValue: RawValue

        public init() {
          self.rawValue = 0
        }

        public init(rawValue: RawValue) {
          self.rawValue = rawValue
        }

        public  static let nextDay: Self =
          Self (rawValue: 1 << Options.nextDay.rawValue)

        public  static let standard: Self =
          Self (rawValue: 1 << Options.standard.rawValue)
      }
      """
    }
  }

  func testExpansionFailsOnEnumType() {
    assertMacro {
      """
      @MyOptionSet<UInt8>
      enum Animal {
        case dog
      }
      """
    } diagnostics: {
      """
      @MyOptionSet<UInt8>
      ├─ 🛑 'OptionSet' macro can only be applied to a struct
      ╰─ 🛑 'OptionSet' macro can only be applied to a struct
      enum Animal {
        case dog
      }
      """
    }
  }

  func testExpansionFailsWithoutNestedOptionsEnum() {
    assertMacro {
      """
      @MyOptionSet<UInt8>
      struct ShippingOptions {
        static let express: ShippingOptions = [.nextDay, .secondDay]
        static let all: ShippingOptions = [.express, .priority, .standard]
      }
      """
    } diagnostics: {
      """
      @MyOptionSet<UInt8>
      ├─ 🛑 'OptionSet' macro requires nested options enum 'Options'
      ╰─ 🛑 'OptionSet' macro requires nested options enum 'Options'
      struct ShippingOptions {
        static let express: ShippingOptions = [.nextDay, .secondDay]
        static let all: ShippingOptions = [.express, .priority, .standard]
      }
      """
    }
  }

  func testExpansionFailsWithoutSpecifiedRawType() {
    assertMacro {
      """
      @MyOptionSet
      struct ShippingOptions {
        private enum Options: Int {
          case nextDay
        }
      }
      """
    } diagnostics: {
      """
      @MyOptionSet
      ┬───────────
      ├─ 🛑 'OptionSet' macro requires a raw type
      ╰─ 🛑 'OptionSet' macro requires a raw type
      struct ShippingOptions {
        private enum Options: Int {
          case nextDay
        }
      }
      """
    }
  }
}
