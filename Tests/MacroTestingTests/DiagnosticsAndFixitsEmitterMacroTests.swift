import MacroTesting
import XCTest

final class DiagnosticsAndFixitsEmitterMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [DiagnosticsAndFixitsEmitterMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionEmitsDiagnosticsAndFixits() {
    assertMacro {
      """
      @DiagnosticsAndFixitsEmitter
      struct FooBar {
        let foo: Foo
        let bar: Bar
      }
      """
    } diagnostics: {
      """
      @DiagnosticsAndFixitsEmitter
       ┬──────────────────────────
       ├─ ⚠️ This is the first diagnostic.
       │  ✏️ This is the first fix-it.
       │  ✏️ This is the second fix-it.
       ╰─ ℹ️ This is the second diagnostic, it's a note.
      struct FooBar {
        let foo: Foo
        let bar: Bar
      }
      """
    } expansion: {
      """
      struct FooBar {
        let foo: Foo
        let bar: Bar
      }
      """
    }
  }
}
