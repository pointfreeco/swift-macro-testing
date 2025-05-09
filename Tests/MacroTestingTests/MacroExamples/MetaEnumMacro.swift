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

public struct MetaEnumMacro {
  let parentTypeName: TokenSyntax
  let childCases: [EnumCaseElementSyntax]
  let access: DeclModifierListSyntax.Element?
  let parentParamName: TokenSyntax

  init(
    node: AttributeSyntax, declaration: some DeclGroupSyntax, context: some MacroExpansionContext
  ) throws {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw DiagnosticsError(diagnostics: [
        CaseMacroDiagnostic.notAnEnum(declaration).diagnose(at: Syntax(node))
      ])
    }
    
    let enumCaseDecls = enumDecl.memberBlock.members.compactMap {
      $0.decl.as(EnumCaseDeclSyntax.self)?.elements.first
    }
    guard Set(enumCaseDecls.map(\.name.text)).count == enumCaseDecls.count else {
      throw DiagnosticsError(diagnostics: [
        CaseMacroDiagnostic.overloadedCase.diagnose(at: Syntax(node))
      ])
    }

    parentTypeName = enumDecl.name.with(\.trailingTrivia, [])

    access = enumDecl.modifiers.first(where: \.isNeededAccessLevelModifier)

    childCases = enumDecl.caseElements.map { parentCase in
      parentCase.with(\.parameterClause, nil)
    }

    parentParamName = context.makeUniqueName("parent")
  }

  func makeMetaEnum() -> DeclSyntax {
    // FIXME: Why does this need to be a string to make trailing trivia work properly?
    let caseDecls =
      childCases
      .map { childCase in
        "  case \(childCase.name)"
      }
      .joined(separator: "\n")

    return """
      \(access)enum Meta {
      \(raw: caseDecls)
      \(makeMetaInit())
      }
      """
  }

  func makeMetaInit() -> DeclSyntax {
    // FIXME: Why does this need to be a string to make trailing trivia work properly?
    let caseStatements =
      childCases
      .map { childCase in
        """
          case .\(childCase.name):
            self = .\(childCase.name)
        """
      }
      .joined(separator: "\n")

    return """
      \(access)init(_ \(parentParamName): \(parentTypeName)) {
        switch \(parentParamName) {
      \(raw: caseStatements)
        }
      }
      """
  }
}

extension MetaEnumMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let macro = try MetaEnumMacro(node: node, declaration: declaration, context: context)

    return [macro.makeMetaEnum()]
  }
}

extension EnumDeclSyntax {
  var caseElements: [EnumCaseElementSyntax] {
    memberBlock.members.flatMap { member in
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
        return [EnumCaseElementSyntax]()
      }

      return Array(caseDecl.elements)
    }
  }
}

enum CaseMacroDiagnostic {
  case overloadedCase
  case notAnEnum(DeclGroupSyntax)
}

extension CaseMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case .overloadedCase:
      "'@MetaEnum' cannot be applied to enums with overloaded case names."
    case .notAnEnum(let decl):
      "'@MetaEnum' can only be attached to an enum, not \(decl.descriptiveDeclKind(withArticle: true))"
    }
  }

  var diagnosticID: MessageID {
    switch self {
    case .overloadedCase:
      MessageID(domain: "MetaEnumDiagnostic", id: "overloadedCase")
    case .notAnEnum:
      MessageID(domain: "MetaEnumDiagnostic", id: "notAnEnum")
    }
  }

  var severity: DiagnosticSeverity {
    switch self {
    case .overloadedCase: .error
    case .notAnEnum: .error
    }
  }

  func diagnose(at node: Syntax) -> Diagnostic {
    Diagnostic(node: node, message: self)
  }
}

extension DeclGroupSyntax {
  func descriptiveDeclKind(withArticle article: Bool = false) -> String {
    switch self {
    case is ActorDeclSyntax:
      return article ? "an actor" : "actor"
    case is ClassDeclSyntax:
      return article ? "a class" : "class"
    case is ExtensionDeclSyntax:
      return article ? "an extension" : "extension"
    case is ProtocolDeclSyntax:
      return article ? "a protocol" : "protocol"
    case is StructDeclSyntax:
      return article ? "a struct" : "struct"
    case is EnumDeclSyntax:
      return article ? "an enum" : "enum"
    default:
      fatalError("Unknown DeclGroupSyntax")
    }
  }
}
