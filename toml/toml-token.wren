class TomlToken {
  static LEFT_BRACKET { "L_BRACKET" }
  static RIGHT_BRACKET { "R_BRACKET" }
  static LEFT_BRACE { "L_BRACE" }
  static RIGHT_BRACE { "R_BRACE" }
  static EQUALS { "EQUALS" }
  static COMMA { "COMMA" }
  static DOT { "DOT" }
  static EOF { "EOF" }
  static PLUS { "PLUS" }
  static MINUS { "MINUS" }
  static NEWLINE { "NEWLINE" }

  static BASIC_STRING { "BASIC_STRING" }
  static LITERAL_STRING { "LITERAL_STRING" }
  static MULTILINE_BASIC_STRING { "MULTILINE_BASIC_STRING" }
  static MULTILINE_LITERAL_STRING { "MULTILINE_LITERAL_STRING" }
  static INTEGER { "INTEGER" }
  static FLOAT { "FLOAT" }

  static TRUE { "TRUE" }
  static FALSE { "FALSE" }

  static DATE { "DATE" }
  static TIME { "TIME" }
  static DATETIME { "DATETIME" }
  static IDENTIFIER { "IDENTIFIER" }
}

class Token {
  construct new(type, lexeme, literal, line) {
    _type = type
    _lexeme = lexeme
    _literal = literal
    _line = line
  }
  type { _type }
  literal { _literal }
  lexeme { _lexeme }

  toString {
    if (_type == TomlToken.IDENTIFIER ||
      _type == TomlToken.DATE ||
      _type == TomlToken.TIME ||
      _type == TomlToken.DATETIME ||
      _type == TomlToken.BASIC_STRING ||
      _type == TomlToken.LITERAL_STRING ||
      _type == TomlToken.MULTILINE_BASIC_STRING ||
      _type == TomlToken.MULTILINE_LITERAL_STRING ||
      _type == TomlToken.INTEGER ||
      _type == TomlToken.FLOAT) {
      return "%(_type)(%(_lexeme))"
    }
    if (_literal != null) {
      return _literal.toString
    }
    return _type
  }
}
