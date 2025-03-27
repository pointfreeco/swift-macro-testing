# ``MacroTesting``

Magical testing tools for Swift macros.

## Overview

This library comes with a tool for testing macros that is more powerful and ergonomic than the
default tool that comes with SwiftSyntax. To use the tool, simply specify the macros that you want
to expand as well as a string of Swift source code that makes use of the macro.

For example, to test the `#stringify` macro that comes with SPM's macro template all one needs to
do is write the following: 

```swift
import MacroTesting
import Testing

@Suite(.macros([StringifyMacro.self]))
struct StringifyTests {
  @Test func stringify() {
    assertMacro {
      """
      #stringify(a + b)
      """
    }
  }
}
```

When you run this test the library will automatically expand the macros in the source code string
and write the expansion into the test file:

```swift
@Suite(.macros([StringifyMacro.self]))
struct StringifyTests {
  @Test func stringify() {
    assertMacro {
    """
    #stringify(a + b)
    """
  } expansion: {
    """
    (a + b, "a + b")
    """
  }
}
```

That is all it takes.

If in the future the macro's output changes, such as adding labels to the tuple's arguments, then
running the test again will produce a nicely formatted message:

```diff
❌ Actual output (+) differed from expected output (−). Difference: …

- (a + b, "a + b")
+ (result: a + b, code: "a + b")
```

You can even have the library automatically re-record the macro expansion directly into your test
file by providing the `record` argument to ``Testing/Trait/macros(_:indentationWidth:record:)``:

```swift
@Suite(.macros([StringifyMacro.self], record: .all))
```

Now when you run the test again the freshest expanded macro will be written to the `expansion` 
trailing closure.

Macro Testing can also test diagnostics, such as warnings, errors, notes, and fix-its. When a macro
expansion emits a diagnostic, it will render inline in the test. For example, a macro that adds
completion handler functions to async functions may emit an error and fix-it when it is applied to a
non-async function. The resulting macro test will fully capture this information, including where
the diagnostics are emitted, how the fix-its are applied, and how the final macro expands:

```swift
func testNonAsyncFunctionDiagnostic() {
  assertMacro {
    """
    @AddCompletionHandler
    func f(a: Int, for b: String) -> String {
      return b
    }
    """
  } diagnostics: {
    """
    @AddCompletionHandler
    func f(a: Int, for b: String) -> String {
    ┬───
    ╰─ 🛑 can only add a completion-handler variant to an 'async' function
       ✏️ add 'async'
      return b
    }
    """
  } fixes: {
    """
    @AddCompletionHandler
    func f(a: Int, for b: String) async -> String {
      return b
    }
    """
  } expansion: {
    """
    func f(a: Int, for b: String) async -> String {
      return b
    }

    func f(a: Int, for b: String, completionHandler: @escaping (String) -> Void) {
      Task {
        completionHandler(await f(a: a, for: b, value))
      }
    }
    """
  }
}
```

## Topics

### Essentials

- ``assertMacro(_:indentationWidth:record:of:diagnostics:fixes:expansion:fileID:file:function:line:column:)-8zqk4``
- ``withMacroTesting(indentationWidth:record:macros:operation:)-7cm1s``
