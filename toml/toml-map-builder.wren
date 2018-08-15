import "./toml/toml-ast" for
  TomlNode, TomlArray, TomlTable, TomlArrayTable, TomlDocument, TomlKey,
  TomlUnary, TomlLiteral,TomlValue, TomlKeyValuePair, TomlInlineTable
import "./toml/toml-types" for TomlType
import "./toml/toml-token" for TomlToken

class Scope {
  construct new() {
    _map = {}
  }

  [keyPath] {
    if (keyPath is List) {
      return retrieve(keyPath)
    }
    Fiber.abort("%(keyPath): Expected path to be a List")
  }
  [keyPath]=(value) {
    if (keyPath is List) {
      return set(keyPath, value)
    }
    Fiber.abort("%(keyPath): Expected path to be a List")
  }

  map { _map }

  retrieve(keyPath) {
    var current = _map
    if (keyPath.count == 0) {
      return current
    }

    for (key in keyPath) {
      if (!current.containsKey(key)) {
        return null
      }
      current = current[key]
    }
    return current
  }

  set(keyPath, value) {
    var current = _map
    if (keyPath.count == 0) {
      return current
    }

    for (key in keyPath) {
      if (!current.containsKey(key)) {
        current[key] = {}
      }
      current = current[key]
    }
    return current
  }
}

class TomlMapBuilder {
  construct new(document) {
    if (document is TomlDocument) {
      _document = document
      _map = {}
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
    } else if (tomlNode is TomlInlineTable) {
      return visitInlineTable(tomlNode)
    } else if (tomlNode is TomlArrayTable) {
      return visitArrayTable(tomlNode)
    } else if (tomlNode is TomlArray) {
      return visitArray(tomlNode)
    } else if (tomlNode is TomlKeyValuePair) {
      return visitKeyPair(tomlNode)
    } else if (tomlNode is TomlTable) {
      return visitTable(tomlNode)
    }

    return null
  }

  traverseMap(keyPath) {
    return traverseMap(_map, keyPath, null)
  }

  traverseMap(map, keyPath) {
    return traverseMap(map, keyPath, null)
  }

  traverseMap(map, keyPath, replacementStrategy) {
    var current = map
    if (keyPath.count == 0) {
      return current
    }

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
    if (node.type == TomlType.FLOAT && node.literal == "inf") {
      return (1/0)
    } else if (node.type == TomlType.FLOAT && node.literal == "nan") {
      return (0/0)
    } else {
      return node.literal
    }
  }

  visitValue(node) {
    System.print("IDENTIFIER: %(node.value.type)")
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

  visitArray(node) {
    var array = []
    for (value in node.values) {
      array.add(evaluate(value))
    }
    return array
  }


  visitKeyPair(pair) {
    var pairKey = evaluate(pair.key)
    var pairValue = evaluate(pair.value)
    return pairValue
  }

  visitInlineTable(table) {
    var map = {}
    for (pair in table.pairs) {
      var keyPath = evaluate(pair.key)
      var finalMap = traverseMap(map, keyPath[0...-1])
      finalMap[keyPath[-1]] = evaluate(pair)
    }
    return map
  }

  visitTable(table) {
    var currentTable = null
    var tablePath = []
    if (table.key != null) {
      tablePath = evaluate(table.key)
      currentTable = traverseMap(tablePath)
    } else {
      currentTable = _map
    }

    // TODO: Disallow redeclaration of tables
    //var map = traverseMap(key)

    for (pair in table.pairs) {
      var mapTablePath = tablePath[0..-1]
      var keyPath = evaluate(pair.key)
      if (keyPath.count > 1) {
        for (key in keyPath[0...-1]) {
          mapTablePath.add(key)
        }
      }
      var finalMap = traverseMap(mapTablePath)
      finalMap[keyPath[-1]] = evaluate(pair)
    }
  }

  visitArrayTable(table) {
    var tableArrayPath = evaluate(table.key)
    var container = traverseMap(tableArrayPath[0...-1])
    var tableKey = tableArrayPath[-1]
    if (!container.containsKey(tableKey)) {
      container[tableKey] = []
    }

    // TODO: Stricter type checking
    var tableArray = container[tableKey]
    if (tableArray is List) {
      tableArray.add(visitInlineTable(table))
    } else {
      Fiber.abort("Can't redefine a key for array of tables")
    }


  }

  visitDocument(document) {
    for (table in document.tables) {
      var finalisedTable = evaluate(table)
    }

    return _map
  }
}
