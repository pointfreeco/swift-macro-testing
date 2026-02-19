import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion

extension Array where Element == Diagnostic {
  func underlineHighlights(
    sourceString: String,
    lineNumber: Int,
    column: Int,
    context: BasicMacroExpansionContext
  ) -> String? {
    let (highlightColumns, highlightLineLength) = self.reduce(
      into: (highlightColumns: Set<Int>(), highlightLineLength: column + 1)
    ) { partialResult, diag in
      for highlight in diag.highlights {
        let startLocation = context.location(
          for: highlight.positionAfterSkippingLeadingTrivia, anchoredAt: diag.node, fileName: ""
        )
        let endLocation = context.location(
          for: highlight.endPositionBeforeTrailingTrivia, anchoredAt: diag.node, fileName: ""
        )
        let descr = diag.node.trimmedDescription
        guard
          startLocation.line == lineNumber,
          startLocation.line == endLocation.line,
          descr.isEmpty || sourceString.contains(descr)
        else { continue }
        partialResult.highlightColumns.formUnion(startLocation.column..<endLocation.column)
        partialResult.highlightLineLength = Swift.max(
          partialResult.highlightLineLength, endLocation.column
        )
      }
    }
    guard !highlightColumns.isEmpty else { return nil }
    return String(
      (0..<highlightLineLength).map {
        $0 == column
          ? "┬"
          : highlightColumns.contains($0)
            ? "─"
            : " "
      }
    )
  }
}
