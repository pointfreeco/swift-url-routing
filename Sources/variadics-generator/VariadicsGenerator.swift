//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ArgumentParser

struct Permutation {
  let arity: Int
  // 1 ->
  // 0 -> where P.Output == Void
  let bits: Int64

  func isCaptureless(at index: Int) -> Bool {
    bits & (1 << (-index + arity - 1)) != 0
  }

  var hasCaptureless: Bool {
    bits != 0
  }

  var identifier: String {
    var result = ""
    for i in 0..<arity {
      result.append(isCaptureless(at: i) ? "V" : "O")
    }
    return result
  }

  var capturelessIndices: [Int] {
    (0..<arity).filter { isCaptureless(at: $0) }
  }

  var captureIndices: [Int] {
    (0..<arity).filter { !isCaptureless(at: $0) }
  }
}

struct Permutations: Sequence {
  let arity: Int

  struct Iterator: IteratorProtocol {
    let arity: Int
    var counter = Int64(0)

    mutating func next() -> Permutation? {
      guard counter & (1 << arity) == 0 else {
        return nil
      }
      defer { counter += 1 }
      return Permutation(arity: arity, bits: counter)
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(arity: arity)
  }
}

func output(_ content: String) {
  print(content, terminator: "")
}

func outputForEach<C: Collection>(
  _ elements: C, separator: String, _ content: (C.Element) -> String
) {
  for i in elements.indices {
    output(content(elements[i]))
    if elements.index(after: i) != elements.endIndex {
      output(separator)
    }
  }
}

struct VariadicsGenerator: ParsableCommand {
  func run() throws {
    output("// BEGIN AUTO-GENERATED CONTENT\n\n")

    for arity in 2...6 {
      emitPathZipDeclarations(arity: arity)
    }

    output("// END AUTO-GENERATED CONTENT\n")
  }

  func emitPathZipDeclarations(arity: Int) {
    for permutation in Permutations(arity: arity) {
      // Emit type declaration.
      let typeName = "PathZip\(permutation.identifier)"
      output("extension PathBuilder {\n  public struct \(typeName)<")
      outputForEach(0..<arity, separator: ", ") { "P\($0): Parser" }
      output(">: Parser\nwhere\n    ")
      outputForEach(0..<arity, separator: ",\n    ") { "P\($0).Input == Substring" }
      if permutation.hasCaptureless {
        output(",\n    ")
        outputForEach(permutation.capturelessIndices, separator: ",\n    ") {
          "P\($0).Output == Void"
        }
      }
      output("\n{\n    public let ")
      outputForEach(0..<arity, separator: ", ") { "p\($0): P\($0)" }
      output("\n\n    @inlinable public init(")
      outputForEach(0..<arity, separator: ", ") { "_ p\($0): P\($0)" }
      output(") {\n      ")
      outputForEach(0..<arity, separator: "\n      ") { "self.p\($0) = p\($0)" }
      output(
        "\n    }\n\n    @inlinable public func parse(_ input: inout URLRequestData) throws -> (\n"
      )
      outputForEach(permutation.captureIndices, separator: ",\n") { "      P\($0).Output" }
      output("\n    ) {\n      guard input.path.count >= \(arity) else { throw RoutingError() }")
      output("\n      ")
      outputForEach(0..<arity, separator: "\n      ") {
        """
        \(permutation.isCaptureless(at: $0) ? "" : "let o\($0) = ")try Parse { p\($0); End() }\
        .parse(input.path.removeFirst())
        """
      }
      output("\n      return (")
      outputForEach(permutation.captureIndices, separator: ", ") { "o\($0)" }
      output(")\n    }\n  }\n}\n\n")

      // Emit printer extension.
      output("extension PathBuilder.\(typeName): ParserPrinter\nwhere\n  ")
      outputForEach(0..<arity, separator: ",\n  ") { "P\($0): ParserPrinter" }
      if permutation.hasCaptureless {
        output(",\n  ")
        outputForEach(permutation.capturelessIndices, separator: ",\n  ") {
          "P\($0).Output == Void"
        }
      }
      output("\n{\n  @inlinable public func print(\n    _ output: (\n")
      outputForEach(permutation.captureIndices, separator: ",\n") { "      P\($0).Output" }
      output("\n    ),\n    into input: inout URLRequestData\n  ) rethrows {\n    ")
      outputForEach((0..<arity).reversed(), separator: "\n    ") {
        let output =
          permutation.isCaptureless(at: $0)
          ? ""
          : permutation.captureIndices.count == 1
            ? "output"
            : "output.\(permutation.captureIndices.firstIndex(of: $0)!)"
        return "input.path.prepend(try p\($0).print(\(output)))"
      }
      output("\n  }\n}\n\n")

      // Emit builder.
      output("extension PathBuilder {\n")
      output("  @inlinable public static func buildBlock<")
      outputForEach(0..<arity, separator: ", ") { "P\($0)" }
      output(">(\n    ")
      outputForEach(0..<arity, separator: ", ") { "_ p\($0): P\($0)" }
      output("\n  ) -> \(typeName)<")
      outputForEach(0..<arity, separator: ", ") { "P\($0)" }
      output("> {\n")
      output("    \(typeName)(")
      outputForEach(0..<arity, separator: ", ") { "p\($0)" }
      output(")\n  }\n}\n\n")
    }
  }
}
