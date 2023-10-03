import MacroTesting
import XCTest

final class AddAsyncMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [AddAsyncMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionTransformsFunctionWithResultCompletionToAsyncThrows() {
    assertMacro {
      #"""
      @AddAsync
      func c(a: Int, for b: String, _ value: Double, completionBlock: @escaping (Result<String, Error>) -> Void) -> Void {
        completionBlock(.success("a: \(a), b: \(b), value: \(value)"))
      }
      """#
    } expansion: {
      #"""
      func c(a: Int, for b: String, _ value: Double, completionBlock: @escaping (Result<String, Error>) -> Void) -> Void {
        completionBlock(.success("a: \(a), b: \(b), value: \(value)"))
      }

      func c(a: Int, for b: String, _ value: Double) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
          c(a: a, for: b, value) { returnValue in

            switch returnValue {
            case .success(let value):
              continuation.resume(returning: value)
            case .failure(let error):
              continuation.resume(throwing: error)
            }
          }
        }
      }
      """#
    }
  }

  func testExpansionTransformsFunctionWithBoolCompletionToAsync() {
    assertMacro {
      """
      @AddAsync
      func d(a: Int, for b: String, _ value: Double, completionBlock: @escaping (Bool) -> Void) -> Void {
        completionBlock(true)
      }
      """
    } expansion: {
      """
      func d(a: Int, for b: String, _ value: Double, completionBlock: @escaping (Bool) -> Void) -> Void {
        completionBlock(true)
      }

      func d(a: Int, for b: String, _ value: Double) async -> Bool {
        await withCheckedContinuation { continuation in
          d(a: a, for: b, value) { returnValue in

            continuation.resume(returning: returnValue)
          }
        }
      }
      """
    }
  }

  func testExpansionOnStoredPropertyEmitsError() {
    assertMacro {
      """
      struct Test {
        @AddAsync
        var name: String
      }
      """
    } diagnostics: {
      """
      struct Test {
        @AddAsync
        ┬────────
        ╰─ 🛑 @addAsync only works on functions
        var name: String
      }
      """
    }
  }

  func testExpansionOnAsyncFunctionEmitsError() {
    assertMacro {
      """
      struct Test {
        @AddAsync
        async func sayHello() {
        }
      }
      """
    } diagnostics: {
      """
      struct Test {
        @AddAsync
        ┬────────
        ╰─ 🛑 @addAsync requires an function that returns void
        async func sayHello() {
        }
      }
      """
    }
  }
}
