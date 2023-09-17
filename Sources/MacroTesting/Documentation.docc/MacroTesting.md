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
import XCTest

class StringifyTests: XCTestCase {
  func testStringify() {
    assertMacro(["stringify": StringifyMacro.self]) {
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
func testStringify() {
  assertMacro(["stringify": StringifyMacro.self]) {
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
file by providing the `record` argument to
``assertMacro(_:record:of:diagnostics:fixes:expansion:file:function:line:column:)-6hxgm``
```swift
assertMacro(["stringify": StringifyMacro.self], record: true) {
  """
  #stringify(a + b)
  """
} expansion: {
  """
  (a + b, "a + b")
  """
}
```

Now when you run the test again the freshest expanded macro will be written to the `expansion` 
trailing closure.

If you're writing many tests for a macro, you can avoid the repetitive work of specifying the macros
in each assertion by using XCTest's `invokeTest` method to wrap each test with Macro Testing
configuration:

```swift
class StringifyMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      macros: ["stringify": StringifyMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testStringify() {
    assertMacro {  // 👈 No need to specify the macros being tested
      """
      #stringify(a + b)
      """
    } expansion: {
      """
      (a + b, "a + b")
      """
    }
  }

  // ...
}
```

You can pass the `isRecording` parameter to
``withMacroTesting(isRecording:macros:operation:)-2vypn`` to re-record every assertion in the test
case (or suite, if you're using your own custom base test case class):

```swift
override func invokeTest() {
  withMacroTesting(
    isRecording: true
  ) {
    super.invokeTest()
  }
}
```

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

- ``assertMacro(_:record:of:diagnostics:fixes:expansion:file:function:line:column:)-6hxgm``
- ``withMacroTesting(isRecording:macros:operation:)-2vypn``
