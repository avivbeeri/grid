import "./toml/toml-ast" for
  TomlNode, TomlArray, TomlTable, TomlArrayTable, TomlDocument, TomlKey,
  TomlUnary, TomlLiteral,TomlValue, TomlKeyValuePair, TomlInlineTable
import "./toml/toml-types" for TomlType
import "./toml/toml-token" for TomlToken

class ReplacementStrategy {
  static ALLOW { "allow" }
  static DENY { "deny" }
}

class TomlMapBuilder {
  construct new(document) {
    if (document is TomlDocument) {
      _document = document
      _map = {}
      _symbolTable = {}
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
    return traverseMap(_map, keyPath, ReplacementStrategy.ALLOW)
  }

  traverseMap(map, keyPath) {
    return traverseMap(map, keyPath, ReplacementStrategy.ALLOW)
  }

  traverseMap(map, keyPath, replacementStrategy) {
    var current = map
    if (keyPath.count == 0) {
      return current
    }

    var level = 0
    var totalLevels = keyPath.count
    for (key in keyPath) {
      if (level < totalLevels && current is List) {
        current = current[-1] || {}
      }
      if (!current.containsKey(key)) {
        if (replacementStrategy == ReplacementStrategy.ALLOW) {
          // Create if missing
          current[key] = {}
        }
      }
      // Now that we have created it if we wanted,
      // try to retrieve.
      if (replacementStrategy == ReplacementStrategy.ALLOW) {
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
      if (finalMap.containsKey(keyPath[-1])) {
        Fiber.abort("Redefining [%(pair.key)] with table")
      }
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
      //currentTable[tablePath[-1]] = visitInlineTable(table)
    } else {
      currentTable = _map
      //_map = visitInlineTable(table)
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
      if (finalMap.containsKey(keyPath[-1])) {
        Fiber.abort("Attempting to redefine %(pair.key) with %(pair.value)")
      }
      finalMap[keyPath[-1]] = evaluate(pair)


      /*
      if (_symbolTable.containsKey(table.key.toString) && _symbolTable[table.key.toString] != TomlArrayTable) {
        System.print(_symbolTable)
          Fiber.abort("Attempting to redefine static array %(table.key) as array of tables")
      } else {
        _symbolTable[table.key.toString] = TomlArrayTable
      }
      */

    }

    return currentTable
  }

  visitArrayTable(table) {
    var tableArrayPath = evaluate(table.key)
    if (_symbolTable.containsKey(table.key.toString) && _symbolTable[table.key.toString] != TomlArrayTable) {
      System.print(_symbolTable)
      Fiber.abort("Attempting to redefine static array %(table.key) as array of tables")
    } else {
      _symbolTable[table.key.toString] = TomlArrayTable
    }
    var container = traverseMap(tableArrayPath[0...-1])
    var tableKey = tableArrayPath[-1]

    if (container is List) {
      container = container[-1] || {}
    }
    if (!container.containsKey(tableKey)) {
      container[tableKey] = []
    } else {
      // Check for redefinition
    }

    var tableArray = container[tableKey]
    if (tableArray is List) {
      tableArray.add(visitInlineTable(table))
    } else {
      Fiber.abort("Can't redefine a key for array of tables")
    }
  }

  visitDocument(document) {
    for (table in document.tables) {
      evaluate(table)
    }

    return _map
  }
}
