import MacroTesting
import XCTest

final class ObservableMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      macros: [
        "Observable": ObservableMacro.self,
        "ObservableProperty": ObservablePropertyMacro.self,
      ]
    ) {
      super.invokeTest()
    }
  }

  func testExpansion() {
    assertMacro {
      """
      @Observable
      final class Dog {
        var name: String?
        var treat: Treat?

        var isHappy: Bool = true

        init() {}

        func bark() {
          print("bork bork")
        }
      }
      """
    } expansion: {
      #"""
      final class Dog {
        var name: String? {
          get {
            _registrar.beginAccess(\.name)
            defer {
              _registrar.endAccess()
            }
            return _storage.name
          }
          set {
            _registrar.beginAccess(\.name)
            _registrar.register(observable: self, willSet: \.name, to: newValue)
            defer {
              _registrar.register(observable: self, didSet: \.name)
              _registrar.endAccess()
            }
            _storage.name = newValue
          }
        }
        var treat: Treat? {
          get {
            _registrar.beginAccess(\.treat)
            defer {
              _registrar.endAccess()
            }
            return _storage.treat
          }
          set {
            _registrar.beginAccess(\.treat)
            _registrar.register(observable: self, willSet: \.treat, to: newValue)
            defer {
              _registrar.register(observable: self, didSet: \.treat)
              _registrar.endAccess()
            }
            _storage.treat = newValue
          }
        }

        var isHappy: Bool {
          get {
            _registrar.beginAccess(\.isHappy)
            defer {
              _registrar.endAccess()
            }
            return _storage.isHappy
          }
          set {
            _registrar.beginAccess(\.isHappy)
            _registrar.register(observable: self, willSet: \.isHappy, to: newValue)
            defer {
              _registrar.register(observable: self, didSet: \.isHappy)
              _registrar.endAccess()
            }
            _storage.isHappy = newValue
          }
        }

        init() {}

        func bark() {
          print("bork bork")
        }

        let _registrar = ObservationRegistrar<Dog >()

        public nonisolated func addObserver(_ observer: some Observer<Dog >) {
          _registrar.addObserver(observer)
        }

        public nonisolated func removeObserver(_ observer: some Observer<Dog >) {
          _registrar.removeObserver(observer)
        }

        private func withTransaction<T>(_ apply: () throws -> T) rethrows -> T {
          _registrar.beginAccess()
          defer {
            _registrar.endAccess()
          }
          return try apply()
        }

        private struct Storage {

          var name: String?
          var treat: Treat?

          var isHappy: Bool = true
        }

        private var _storage = Storage()
      }

      extension Dog: Observable {
      }
      """#
    }
  }
}
