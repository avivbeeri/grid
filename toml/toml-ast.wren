import "./toml/toml-token" for Token, TomlToken
import "./toml/toml-types" for TomlType


class TomlArray {
  construct new() {
    _values = []
  }
  construct new(values) {
    _values = values
  }
  toString { _values.toString }
  type { TomlType.ARRAY }
}

class TomlNode {
  accept(visitor) {
    return visitor.visit(this)
  }
}

class TomlTable is TomlNode {
  construct new() {
    _pairs = []
    _key = null
  }
  construct new(key) {
    _key = key
    _pairs = []
  }
  add(pair) { _pairs.add(pair) }
  pairs { _pairs }
  key { _key }
  toString {
    var out = "{\n"
    if (_key != null) {
      out = out + "[%(table.key)]\n"
    }
    for (pair in _pairs) {
      out = out + "%(pair.key): %(pair.value)\n"
    }
    return out + "}"
  }
}

class TomlArrayTable is TomlTable {
  construct new(key) {
    super(key)
  }
}

class TomlKeyValuePair is TomlNode {
  construct new(key, value) {
    _key = key
    _value = value
  }
  key { _key }
  value { _value }
}

class TomlKey is TomlNode {
  construct new(path) {
    _path = path
  }

  toString {
    var out = ""
    for (i in 0..._path.count) {
      out = out + _path[i].toString
      if (i < _path.count - 1) {
        out = out + "."
      }
    }
   return out
  }
}

class TomlUnary is TomlNode {
  construct new(operator, value) {
    _operator = operator
    _value = value
  }
  toString { (_operator.type == TomlToken.PLUS ? "+" : "-") + _value.toString }
  type { _value.type }
}

class TomlLiteral is TomlNode {
  construct new(literal, type) {
    _literal = literal
    _type = type
  }
  literal { _literal }
  type { _type }
  toString { _literal.toString }
}

class TomlValue is TomlNode {
  construct new(value, type) {
    _value = value
    _type = type
  }
  type { _type }
  value { _value }
  toString { _value.toString }
}

class TomlDocument is TomlTable {
  construct new() {
    super()
    _tables = []
    _arrayTables = []
  }

  addTable(key) {
    return _tables.add(TomlTable.new(key))
  }

  addArrayTable(key) {
    return _arrayTables.add(TomlArrayTable.new(key))
  }

  tables {
    var tables = _tables[0..-1]
    tables.add(this)
    return tables
  }

  arrayTables { _arrayTables }
}
