# Macro Testing

[![CI](https://github.com/pointfreeco/swift-macro-testing/workflows/CI/badge.svg)](https://github.com/pointfreeco/swift-macro-testing/actions?query=workflow%3ACI)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](https://www.pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-macro-testing%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-macro-testing)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-macro-testing%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-macro-testing)

Magical testing tools for Swift macros.

![](https://pointfreeco-blog.s3.amazonaws.com/posts/0114-macro-testing/macro-testing-full.gif)

## Learn more

This library was designed to support libraries and episodes produced for [Point-Free][point-free], a
video series exploring the Swift programming language hosted by [Brandon Williams][mbrandonw] and
[Stephen Celis][stephencelis].

You can watch all of the episodes [here][macro-testing-episodes].

<a href="https://www.pointfree.co/episodes/ep250-testing-debugging-macros-part-1">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0250.jpeg" width="600">
</a>

## Motivation

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
  } matches: {
    """
    (a + b, "a + b")
    """
  }
}
```

That is all it takes.

If in the future the macro's output changes, such as adding labels to the tuple's arguments, then
running the test again will produce a nicely formatted message:

> ❌ failed - Actual output (+) differed from expected output (−). Difference: …
> 
> ```diff
> - (a + b, "a + b")
> + (result: a + b, code: "a + b")
> ```

You can even have the library automatically re-record the macro expansion directly into your test
file by providing the `record` argument to `assertMacro`:

```swift
assertMacro(["stringify": StringifyMacro.self], record: true) {
  """
  #stringify(a + b)
  """
} matches: {
  """
  (a + b, "a + b")
  """
}
```

Now when you run the test again the freshest expanded macro will be written to the `matches` 
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
    } matches: {
      """
      (a + b, "a + b")
      """
    }
  }

  // ...
}
```

You can pass the `isRecording` parameter to `withMacroTesting` to re-record every assertion in the
test case (or suite, if you're using your own custom base test case class):

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
non-async function. The resulting macro test will fully capture this information:

```swift
func testNonAsyncFunctionDiagnostic() {
  assertMacro {
    """
    @AddCompletionHandler
    func f(a: Int, for b: String, _ value: Double) -> String {
      return b
    }    
    """
  } matches: {
    """
    @AddCompletionHandler
    func f(a: Int, for b: String, _ value: Double) -> String {
    ┬───
    ╰─ 🛑 can only add a completion-handler variant to an 'async' function
       ✏️ add 'async'
      return b
    }
    """
  }
}
```

## Documentation

The latest documentation for this library is available [here][macro-testing-docs].

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[macro-testing-docs]: http://pointfreeco.github.io/swift-macro-testing/main/documentation/macrotesting
[macro-testing-episodes]: https://www.pointfree.co/episodes/ep250-testing-debugging-macros-part-1
[mbrandonw]: https://github.com/mbrandonw
[point-free]: https://www.pointfree.co
[stephencelis]: https://github.com/stephencelis
