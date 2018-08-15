import "./toml/toml-ast" for
  TomlNode, TomlArray, TomlTable, TomlArrayTable, TomlDocument, TomlKey,
  TomlUnary, TomlLiteral,TomlValue, TomlKeyValuePair
import "./toml/toml-types" for TomlType
import "./toml/toml-token" for TomlToken

class TomlMapBuilder {
  construct new(document) {
    if (document is TomlDocument) {
      _document = document
      _map = {}
      _currentPath = []
    } else {
      Fiber.abort("%(document) is not a TOML Document")
    }
  }

  build() {
    return evaluate(_document)
  }

  evaluate(node) {
    return node.accept(this)
  }

  visit(tomlNode) {
    if (tomlNode is TomlDocument) {
      return visitDocument(tomlNode)
    } else if (tomlNode is TomlLiteral) {
      return visitLiteral(tomlNode)
    } else if (tomlNode is TomlValue) {
      return visitValue(tomlNode)
    } else if (tomlNode is TomlUnary) {
      return visitUnary(tomlNode)
    } else if (tomlNode is TomlKey) {
      return visitKey(tomlNode)
    } else if (tomlNode is TomlTable) {
      return visitTable(tomlNode)
    } else if (tomlNode is TomlArrayTable) {
      return visitArrayTable(tomlNode)
    } else if (tomlNode is TomlArray) {
      return visitArray(tomlNode)
    } else if (tomlNode is TomlKeyValuePair) {
      return visitKeyPair(tomlNode)
    }

    return null
  }

  traverseMap(keyPath) {
    traverseMap(keyPath, null)
  }

  traverseMap(keyPath, replacementStrategy) {
    var current = _map

    for (key in keyPath) {
      if (!current.containsKey(key)) {
        if (replacementStrategy == null) {
          // Create if missing
          current[key] = {}
        }
      }
      // Now that we have created it if we wanted,
      // try to retrieve.
      if (replacementStrategy == null) {
        // Append
        current = current[key]
      }

    }
    return current
  }

  visitLiteral(node) {
    // TODO: Handle dates?
    return node.literal
  }

  visitValue(node) {
    System.print("Value: %(node.value)")
    // Do we need to interpret NaN/Infinity here?
    return node.value
  }

  visitUnary(node) {
    var operator = node.operator
    var sign = (operator == TomlToken.PLUS ? 1 : -1)
    var value = evaluate(node.value)
    return sign * value
  }

  visitKey(node) {
    return node.path
  }

  visitArray(pair) {}
  visitArrayTable(pair) {}

  visitKeyPair(pair) {
    var pairKey = evaluate(pair.key)
    var pairValue = evaluate(pair.value)
    /*
    var finalMap = traverseMap(pairKey[0...-1])
    finalMap[pairKey[-1]] = pairValue
    */

    System.print("%(pair.key): %(pair.value)")
  }

  visitTable(table) {
    if (table.key != null) {
      var keyPath = evaluate(table.key)
      _currentPath = keyPath
    }
    // System.print(table)

    // TODO: Disallow redeclaration of tables
    //var map = traverseMap(key)

    for (pair in table.pairs) {
      evaluate(pair)
    }
  }

  visitDocument(document) {
    for (table in document.tables) {
      System.print(table)
      evaluate(table)
    }

    return _map
  }
}
