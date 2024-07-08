#if canImport(Testing)
  @_spi(Experimental) import MacroTesting
  import Testing

  @Suite(
    .macros(
      //record: .failed,
      macros: ["URL": URLMacro.self]
    )
  )
  struct URLMacroSwiftTestingTests {
    @Test
    func expansionWithMalformedURLEmitsError() {
      assertMacro {
        """
        let invalid = #URL("https://not a url.com")
        """
      } diagnostics: {
        """
        let invalid = #URL("https://not a url.com")
                      ┬────────────────────────────
                      ╰─ 🛑 malformed url: "https://not a url.com"
        """
      }
    }

    @Test
    func expansionWithStringInterpolationEmitsError() {
      assertMacro {
        #"""
        #URL("https://\(domain)/api/path")
        """#
      } diagnostics: {
        #"""
        #URL("https://\(domain)/api/path")
        ┬─────────────────────────────────
        ╰─ 🛑 #URL requires a static string literal
        """#
      }
    }

    @Test
    func expansionWithValidURL() {
      assertMacro {
        """
        let valid = #URL("https://swift.org/")
        """
      } expansion: {
        """
        let valid = URL(string: "https://swift.org/")!
        """
      }
    }
  }
#endif
