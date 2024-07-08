import MacroTesting
import XCTest

final class AddCompletionHandlerTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [AddCompletionHandlerMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionTransformsAsyncFunctionToCompletion() {
    assertMacro {
      """
      @AddCompletionHandler
      func f(a: Int, for b: String, _ value: Double) async -> String {
        return b
      }
      """
    } expansion: {
      """
      func f(a: Int, for b: String, _ value: Double) async -> String {
        return b
      }

      func f(a: Int, for b: String, _ value: Double, completionHandler: @escaping (String) -> Void) {
        Task {
          completionHandler(await f(a: a, for: b, value))
        }

      }
      """
    }
  }

  func testExpansionOnStoredPropertyEmitsError() {
    assertMacro {
      """
      struct Test {
        @AddCompletionHandler
        var value: Int
      }
      """
    } diagnostics: {
      """
      struct Test {
        @AddCompletionHandler
        ┬────────────────────
        ╰─ 🛑 @addCompletionHandler only works on functions
        var value: Int
      }
      """
    }
  }

  func testExpansionOnNonAsyncFunctionEmitsErrorWithFixItSuggestion() {
    assertMacro {
      """
      struct Test {
        @AddCompletionHandler
        func fetchData() -> String {
          return "Hello, World!"
        }
      }
      """
    } diagnostics: {
      """
      struct Test {
        @AddCompletionHandler
        func fetchData() -> String {
        ┬───
        ╰─ 🛑 can only add a completion-handler variant to an 'async' function
           ✏️ add 'async'
          return "Hello, World!"
        }
      }
      """
    } fixes: {
      """
      struct Test {
        @AddCompletionHandler
        func fetchData() async-> String {
          return "Hello, World!"
        }
      }
      """
    } expansion: {
      """
      struct Test {
        func fetchData() async-> String {
          return "Hello, World!"
        }

        func fetchData(completionHandler: @escaping (String) -> Void) {
          Task {
            completionHandler(await fetchData())
          }

        }
      }
      """
    }
  }
}
