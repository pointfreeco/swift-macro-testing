import MacroTesting
import XCTest

final class AutoObserveMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      operators: {
        """
        infix operator <~: AssignmentPrecedence
        """
      },
      macros: [AutoObserveMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testExpansionAddsObservationBlocks() {
    assertMacro {
      """
      @AutoObserve
      override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .red
        self.nameLabel.text <~ model.name
        self.imageView.isHidden <~ model.isAvatarHidden
      }
      """
    } expansion: {
      """
      override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        observe { [weak self] in
          guard let self = self else {
            return
          }

          self.nameLabel.text  = model.name
        }
        observe { [weak self] in
          guard let self = self else {
            return
          }

          self.imageView.isHidden  = model.isAvatarHidden
        }
      }
      """
    }
  }
}
