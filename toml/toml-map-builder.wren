import "./toml/toml-ast" for
  TomlNode, TomlArray, TomlTable, TomlArrayTable, TomlDocument, TomlKey,
  TomlUnary, TomlLiteral,TomlValue, TomlKeyValuePair, TomlInlineTable
import "./toml/toml-types" for TomlType
import "./toml/toml-token" for TomlToken

class CreationStrategy {
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
    return traverseMap(_map, keyPath, CreationStrategy.ALLOW)
  }

  traverseMap(map, keyPath) {
    return traverseMap(map, keyPath, CreationStrategy.ALLOW)
  }

  traverseMap(map, keyPath, creationStrategy) {
    var current = map
    if (keyPath.count == 0) {
      return current
    }

    for (key in keyPath) {
      if (!current.containsKey(key)) {
        if (creationStrategy == CreationStrategy.ALLOW) {
          // Create if missing
          current[key] = {}
        }
      }
      // Now that we have created it if we wanted,
      // try to retrieve.
      // Append
      current = current[key]
      if (current is List) {
        current = current[-1] || {}
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
    var tableKeyPath = []
    if (table.key != null) {
      tableKeyPath = evaluate(table.key)
    }

    for (pair in table.pairs) {
      var keyPath = evaluate(pair.key)
      var finalMap = traverseMap(map, keyPath[0...-1], CreationStrategy.ALLOW)
      var value = evaluate(pair.value)
      var fullKey = TomlKey.new(ListUtils.concat(tableKeyPath, keyPath)).toString
      System.print(finalMap)
      if (!(finalMap is Map)) {
        Fiber.abort("Key %(keyPath[0...-1]) has already been directly defined")
      }
      if (finalMap.containsKey(keyPath[-1]) || (_symbolTable.containsKey(fullKey) && _symbolTable[fullKey] != TomlValue)) {
        Fiber.abort("Redefining [%(pair.key)] with %(value)")
      }

      finalMap[keyPath[-1]] = value
      _symbolTable[fullKey] = TomlValue
    }
    return map
  }

  visitTable(table) {
    var currentTable = null
    var tablePath = []
    if (table.key != null) {
      tablePath = evaluate(table.key)
      currentTable = traverseMap(tablePath[0...-1])
      if (_symbolTable.containsKey(table.key.toString)) {
        Fiber.abort("REDEFINE")
      }
      currentTable[tablePath[-1]] = visitInlineTable(table)
    } else {
      currentTable = _map
      _map = visitInlineTable(table)
    }

    return currentTable
  }

  visitArrayTable(table) {
    var tableArrayPath = evaluate(table.key)

    if (_symbolTable.containsKey(table.key.toString) && _symbolTable[table.key.toString] != TomlArrayTable) {
      Fiber.abort("Attempting to redefine static array %(table.key) as array of tables")
    } else {
      _symbolTable[table.key.toString] = TomlArrayTable
    }

    var container = traverseMap(_map, tableArrayPath[0...-1], CreationStrategy.DENY)
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

class ListUtils {
  static concat(list1, list2) {
    var output = list1[0..-1]
    for (item in list2) {
      output.add(item)
    }
    return output
  }

}
