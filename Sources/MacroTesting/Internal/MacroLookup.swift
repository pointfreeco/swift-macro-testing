import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

#if canImport(SwiftSyntax600)
  typealias MacroLookup = [String: MacroSpec]
#else
  typealias MacroLookup = [String: Macro.Type]
#endif

extension Dictionary where Key == String, Value == Macro.Type {
  var macroLookup: MacroLookup {
    #if canImport(SwiftSyntax600)
      return mapValues { MacroSpec(type: $0) }
    #else
      return self
    #endif
  }
}
