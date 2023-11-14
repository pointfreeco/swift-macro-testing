//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Emits two diagnostics, the first of which is a warning and has two fix-its, and
/// the second is a note and has no fix-its.
public enum DiagnosticsAndFixitsEmitterMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let firstFixIt = FixIt(
      message: SimpleDiagnosticMessage(
        message: "This is the first fix-it.",
        diagnosticID: MessageID(domain: "domain", id: "fixit1"),
        severity: .error),
      changes: [
        .replace(oldNode: Syntax(node), newNode: Syntax(node))  // no-op
      ])
    let secondFixIt = FixIt(
      message: SimpleDiagnosticMessage(
        message: "This is the second fix-it.",
        diagnosticID: MessageID(domain: "domain", id: "fixit2"),
        severity: .error),
      changes: [
        .replace(oldNode: Syntax(node), newNode: Syntax(node))  // no-op
      ])

    context.diagnose(
      Diagnostic(
        node: node.attributeName,
        message: SimpleDiagnosticMessage(
          message: "This is the first diagnostic.",
          diagnosticID: MessageID(domain: "domain", id: "diagnostic2"),
          severity: .warning),
        fixIts: [firstFixIt, secondFixIt]))
    context.diagnose(
      Diagnostic(
        node: node.attributeName,
        message: SimpleDiagnosticMessage(
          message: "This is the second diagnostic, it's a note.",
          diagnosticID: MessageID(domain: "domain", id: "diagnostic2"),
          severity: .note)))

    return []
  }
}
