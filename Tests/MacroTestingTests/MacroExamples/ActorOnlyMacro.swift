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

enum ActorOnlyMacroDiagnostic {
  case requiresActor
}

extension ActorOnlyMacroDiagnostic: DiagnosticMessage {

  var message: String {
    switch self {
    case .requiresActor:
      return "'ActorOnly' macro can only be applied to an actor"
    }
  }

  var severity: DiagnosticSeverity { .error }

  var diagnosticID: MessageID {
    MessageID(domain: "Swift", id: "ActorOnly.\(self)")
  }
}

public struct ActorOnlyMacro: MemberMacro {
  public static func expansion(
    of attribute: AttributeSyntax,
    providingMembersOf decl: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
      // Only apply to actors.
      guard decl.is(ActorDeclSyntax.self) else {
          // Offer a fix-it to remove the attribute
          let fixit = FixIt(message: SimpleDiagnosticMessage(message: "Remove '@ActorOnly' attribute",
                                                             diagnosticID: MessageID(domain: "Swift", id: "OptionSet.fixit"),
                                                             severity: .error),
                            changes: [
                                // Doesn't account for the fact that there may be other attributes present, but for
                                // this unit test it should be fine.
                                .replace(oldNode: Syntax(decl.attributes), newNode: Syntax(AttributeListSyntax()))
                            ])

          context.diagnose(Diagnostic(node: decl,
                                      message: ActorOnlyMacroDiagnostic.requiresActor,
                                      fixIt: fixit))
          return []
      }

      return ["static let actorType: Actor.Type = Self.self"]
  }
}
