import MacroTesting
import XCTest

final class FontLiteralMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: [FontLiteralMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionWithNamedArguments() {
    assertMacro {
      """
      #fontLiteral(name: "Comic Sans", size: 14, weight: .thin)
      """
    } expansion: {
      """
      .init(fontLiteralName: "Comic Sans", size: 14, weight: .thin)
      """
    }
  }

  func testExpansionWithUnlabeledFirstArgument() {
    assertMacro {
      """
      #fontLiteral("Copperplate Gothic", size: 69, weight: .bold)
      """
    } expansion: {
      """
      .init(fontLiteralName: "Copperplate Gothic", size: 69, weight: .bold)
      """
    }
  }
}
