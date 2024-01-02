import MacroTesting
import XCTest

final class DefaultFatalErrorImplementationMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      macros: ["defaultFatalErrorImplementation": DefaultFatalErrorImplementationMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testExpansionWhenAttachedToProtocolExpandsCorrectly() {
    assertMacro {
      """
      @defaultFatalErrorImplementation
      protocol MyProtocol {
        func foo()
        func bar() -> Int
      }
      """
    } expansion: {
      """
      protocol MyProtocol {
        func foo()
        func bar() -> Int
      }

      extension MyProtocol {
        func foo() {
          fatalError("whoops 😅")
        }
        func bar() -> Int {
          fatalError("whoops 😅")
        }
      }
      """
    }
  }

  func testExpansionWhenNotAttachedToProtocolProducesDiagnostic() {
    assertMacro {
      """
      @defaultFatalErrorImplementation
      class MyClass {}
      """
    } diagnostics: {
      """
      @defaultFatalErrorImplementation
      ┬───────────────────────────────
      ╰─ 🛑 Macro `defaultFatalErrorImplementation` can only be applied to a protocol
      class MyClass {}
      """
    }
  }

  func testExpansionWhenAttachedToEmptyProtocolDoesNotAddExtension() {
    assertMacro {
      """
      @defaultFatalErrorImplementation
      protocol EmptyProtocol {}
      """
    } expansion: {
      """
      protocol EmptyProtocol {}
      """
    }
  }
}
