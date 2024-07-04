import MacroTesting
import XCTest

class BaseTestCase: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      record: .missing
    ) {
      super.invokeTest()
    }
  }
}
