import MacroTesting
import XCTest

final class PeerValueWithSuffixNameMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [PeerValueWithSuffixNameMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionAddsPeerValueToPrivateActor() {
    assertMacro {
      """
      @PeerValueWithSuffixName
      private actor Counter {
        var value = 0
      }
      """
    } expansion: {
      """
      private actor Counter {
        var value = 0
      }

      var Counter_peer: Int {
        1
      }
      """
    }
  }

  func testExpansionAddsPeerValueToFunction() {
    assertMacro {
      """
      @PeerValueWithSuffixName
      func someFunction() {}
      """
    } expansion: {
      """
      func someFunction() {}

      var someFunction_peer: Int {
          1
      }
      """
    }
  }

  func testExpansionIgnoresVariables() {
    assertMacro {
      """
      @PeerValueWithSuffixName
      var someVariable: Int
      """
    } expansion: {
      """
      var someVariable: Int
      """
    }
  }
}
