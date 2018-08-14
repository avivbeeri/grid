import "./toml/toml-ast" for
  TomlNode, TomlArray, TomlTable, TomlArrayTable, TomlDocument, TomlKey,
  TomlUnary, TomlLiteral,TomlValue, TomlKeyValuePair
import "./toml/toml-types" for TomlType

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
    return _document.accept(this)
  }

  visit(tomlNode) {
    if (tomlNode is TomlDocument) {
      return visitDocument(tomlNode)
    } else if (tomlNode is TomlLiteral) {
    } else if (tomlNode is TomlValue) {
      return visitValue(tomlNode)
    } else if (tomlNode is TomlUnary) {
    } else if (tomlNode is TomlKey) {
    } else if (tomlNode is TomlTable) {
    } else if (tomlNode is TomlArrayTable) {
    } else if (tomlNode is TomlArray) {
    } else if (tomlNode is TomlKeyValuePair) {

    }

    return null
  }

  visitDocument(document) {
    for (table in document.tables) {
      System.print("[%(table.key)]")
      for (pair in table.pairs) {
        System.print("%(pair.key): %(pair.value)")
      }
    }
    for (table in document.arrayTables) {
      System.print("[[%(table.key)]]")
      for (pair in table.pairs) {
        System.print("%(pair.key): %(pair.value)")
      }
    }

    return _map
  }

  visitValue(valueNode) {
    if (valueNode.type == TomlType.INTEGER && valueNode.value is Num && valueNode.value.isInteger) {
      System.print("%(valueNode.value) is integer")
    }
    return valueNode.value
  }
}
