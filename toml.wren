class Toml {
  static run(source) {
    var scanner = TomlScanner.new(source)
    var tokens = scanner.scanTokens()
    var parser = TomlParser.new(tokens)

    /*
    for (token in tokens) {
      System.print(token)
    }
    */
    return parser.parseTokens()
  }
}

class TomlType {
  static STRING { "STRING" }
  static FLOAT { "FLOAT" }
  static INTEGER { "INTEGER" }
  static BOOL { "BOOL" }
  static ARRAY { "ARRAY" }
  static DATETIME { "DATETIME" }
  static INLINE_TABLE { "INLINE_TABLE" }
}

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


class TomlTable {
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

class TomlKeyValuePair {
  construct new(key, value) {
    _key = key
    _value = value
  }
  key { _key }
  value { _value }
}

class TomlKey {
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

class TomlUnary {
  construct new(operator, value) {
    _operator = operator
    _value = value
  }
  toString { (_operator.type == TomlToken.PLUS ? "+" : "-") + _value.toString }
  type { _value.type }
}

class TomlLiteral {
  construct new(literal, type) {
    _literal = literal
    _type = type
  }
  literal { _literal }
  type { _type }
  toString { _literal.toString }
}

class TomlValue {
  construct new(value, type) {
    _value = value
    _type = type
  }
  type { _type }
  toString { _value.toString }
}

class TomlParser {
  construct new(tokens) {
    _tokens = tokens
    _current = 0
  }

  parseTokens() {
    return document()
  }

  document() {
    var document = TomlDocument.new()
    var currentTable = document
    while (!isAtEnd()) {
      if (match([TomlToken.LEFT_BRACKET])) {
        if (match([TomlToken.LEFT_BRACKET])) {
          System.print("ARRAY")
          currentTable = document.addArrayTable(TomlKey.new(keyPath()))
          consume(TomlToken.RIGHT_BRACKET, "Expected ']' after table declaration")
        } else {
          currentTable = document.addTable(TomlKey.new(keyPath()))
        }
        consume(TomlToken.RIGHT_BRACKET, "Expected ']' after table declaration")
      } else {
        currentTable.add(keyValuePair())
      }
      while(match([ TomlToken.NEWLINE ])) {}
    }
    return document
  }

  keyName() {
    if (match([TomlToken.IDENTIFIER])) {
      return previous().lexeme
    } else if (match([TomlToken.BASIC_STRING, TomlToken.LITERAL_STRING])) {
      return previous().literal
    } else if (match([TomlToken.INTEGER])) {
      return previous().literal.toString
    } else {
      Fiber.abort("%(peek()): Invalid key name")
    }
  }

  keyPath() {
    var path = [ keyName() ]
    while (!check(TomlToken.EQUALS) && match([TomlToken.DOT])) {
      path.add(keyName())
    }
    return path
  }

  keyValuePair() {
    var key = keyPath()
    consume(TomlToken.EQUALS, "Expected EQUALS after a key")
    return TomlKeyValuePair.new(TomlKey.new(key), value())
  }

  value() {
    if (match([TomlToken.LEFT_BRACKET])) {
      // Start of an array
      var list = []
      var type = null
      if (peek().type != TomlToken.RIGHT_BRACKET) {
        list.add(value())
        type = list[0].type
      }

      while(match([TomlToken.COMMA])) {
        list.add(value())
        if (type != list[list.count-1].type) {
          Fiber.abort("Arrays must be the same type")
        }
      }
      consume(TomlToken.RIGHT_BRACKET, "Expect ']' after array")
      return TomlArray.new(list)
    } else if (match([TomlToken.LEFT_BRACE])) {
      var table = TomlTable.new()
      while (true) {
        table.add(keyValuePair())
        if (!match([TomlToken.COMMA])) break
      }
      consume(TomlToken.RIGHT_BRACE, "Expect '}' after inline table")
      return table
    } else {
      return unary()
    }
  }

  unary() {
    if (match([TomlToken.PLUS, TomlToken.MINUS])) {
      return TomlUnary.new(previous(), number())
    }
    return literal()
  }

  number() {
    var specialValues = {
      "nan": true,
      "inf": true
    }
    if (peek().type == TomlToken.IDENTIFIER && specialValues[peek().lexeme]) {
      advance()
      return TomlLiteral.new(previous().lexeme, TomlType.FLOAT)
    } else if (match([TomlToken.FLOAT, TomlToken.INTEGER])) {
      return TomlLiteral.new(previous().literal, previous().type)
    }
  }

  literal() {
    if (match([TomlToken.FALSE])) {
      return TomlLiteral.new(false, TomlType.BOOL)
    }
    if (match([TomlToken.TRUE])) {
      return TomlLiteral.new(true, TomlType.BOOL)
    }
    if (match([TomlToken.BASIC_STRING, TomlToken.LITERAL_STRING, TomlToken.MULTILINE_LITERAL_STRING, TomlToken.MULTILINE_BASIC_STRING])) {
      return TomlLiteral.new(previous().literal, TomlType.STRING)
    }
    // TODO: Handle date/time

    var num = number()
    if (num != null) {
        return num
    }
    if (match([ TomlToken.IDENTIFIER])) { TomlValue.new(previous().lexeme, null) }
  }

  consume(tokenType, message) {
    if (check(tokenType)) {
      return advance()
    }
    Fiber.abort("%(peek()) = %(message)")
  }

  match(tokenTypes) {
    if (!tokenTypes is List) { Fiber.abort("Match requires a list of expressions") }
    for (type in tokenTypes) {
      if (check(type)) {
        advance()
        return true
      }
    }
    return false
  }

  check(tokenType) {
    if (isAtEnd()) {
      return false
    }
    return peek().type == tokenType
  }

  advance() {
    if (!isAtEnd()) {
      _current = _current + 1
    }
    return previous()
  }

  isAtEnd() {
    return peek().type == TomlToken.EOF
  }

  peek() {
    return _tokens[_current]
  }

  previous() {
    return _tokens[_current - 1]
  }
}

class TomlScanner {
  construct new(source) {
    _tokens = []
    _source = source

    _start = 0
    _current = 0
    _line = 1
  }

  scanTokens() {
    while (!isAtEnd()) {
      _start = _current
      scanToken()
    }

    _tokens.add(Token.new(TomlToken.EOF, "", null, _line))
    return _tokens
  }

  scanToken() {
    var char = advance()
    if (char == "[") {
      addToken(TomlToken.LEFT_BRACKET)
    } else if (char == "]") {
      addToken(TomlToken.RIGHT_BRACKET)
    } else if (char == "{") {
      addToken(TomlToken.LEFT_BRACE)
    } else if (char == "}") {
      addToken(TomlToken.RIGHT_BRACE)
    } else if (char == "=") {
      addToken(TomlToken.EQUALS)
    } else if (char == ".") {
      addToken(TomlToken.DOT)
    } else if (char == ",") {
      addToken(TomlToken.COMMA)
    } else if (char == "-") {
      addToken(TomlToken.MINUS)
    } else if (char == "+") {
      addToken(TomlToken.PLUS)
    } else if (char == " " || char == "\t") {
      // Ignore whitespace and move on
    } else if (char == "\n" || char == "\r" && match("\n")) {
      _line = _line + 1
      addToken(TomlToken.NEWLINE)
    } else if (char == "#") {
      while (peek() != "\n" && !(peek() == "\r" && match("\n")) && !isAtEnd()) {
        advance()
      }
    } else if (char == "\"" || char == "'") {
      string(char)
    } else if (isDigit(char)) {
      number()
    } else if (isAlpha(char)) {
      identifier()
    } else {
      // Handle keys, values including booleans
      Fiber.abort("Lexing error at %(char)")
    }

  }

  identifier() {
    var keywords = {
      "true": TomlToken.TRUE,
      "false": TomlToken.FALSE
    }
    while (isAlphaNumeric(peek())) {
      advance()
    }
    var text = StringUtils.substring(_source, _start, _current)
    var type = keywords[text]
    if (type == null) {
      type = TomlToken.IDENTIFIER
    }
    addToken(type)
  }

  string(quoteType) {
    // TODO: Support non-basic and multi-line strings
    var type = quoteType == "\"" ? TomlToken.BASIC_STRING : TomlToken.LITERAL_STRING
    var size = 1
    var trim = 0

    var escapes = {
      "b": true,
      "t": true,
      "n": true,
      "f": true,
      "r": true,
      "\"": true,
      "\\": true,
      "u": true,
      "U": true
    }
    if (peek() == quoteType && peekNext() == quoteType) {
      type = quoteType == "\"" ? TomlToken.MULTILINE_BASIC_STRING : TomlToken.MULTILINE_LITERAL_STRING
      size = 3
      advance()
      advance()
      if (peek() == "\n") {
        trim = 1
        advance()
      }
    }
    // TOML allows the first \n to be ignored in multiline strings
    while (peek() != quoteType && !isAtEnd()) {
      if (peek() == "\n" && (type == TomlToken.BASIC_STRING || type == TomlToken.LITERAL_STRING)) {
        Fiber.abort("Trying to split single line string across multiple lines")
      }
      if (size == 1 && peek() == "\\" && escapes[peekNext()] == null) {
        Fiber.abort("Invalid escape sequence in string")
      }
      advance()
    }

    if (isAtEnd()) {
      Fiber.abort("Unterminated string")
      return
    }
    advance()
    if (peek() == quoteType && peekNext() == quoteType) {
      advance()
      advance()
    }
    var value = StringUtils.substring(_source, _start + size + trim, _current - size)

    var outputValue = ""
    var i = 0
    while (i < value.count) {
      if (value[i] == "\\") {
        while (i < value.count && value[i] != "\n") {
          i = i + 1
        }
      } else {
        outputValue = outputValue + value[i]
      }
      i = i + 1
    }

    // TODO: Unescape values
    addToken(type, value)
  }

  isDigit(char) {
    return char.bytes[0] >= "0".bytes[0] && char.bytes[0] <= "9".bytes[0]
  }
  isAlpha(char) {
    return char.bytes[0] >= "A".bytes[0] && char.bytes[0] <= "Z".bytes[0] || char.bytes[0] >= "a".bytes[0] && char.bytes[0] <= "z".bytes[0]
  }

  isAlphaNumeric(char) {
    return isDigit(char) || isAlpha(char) || char == "_" || char == "-"
  }

  isNewline(char, next) {
    // TODO: Implement this
  }

  number() {
    // TODO: Split into Number and Date based on number of digits
    // Enforce RFC3339 Date / Time formats
    while (isDigit(peek())) {
      advance()
    }

    var type = TomlToken.INTEGER

    if (peek() == "-" && isDigit(peekNext())) {
      // Local Date-Time or Local Date
      advance()
      while (isDigit(peek())) {
        advance()
      }
      if (peek() == "-" && isDigit(peekNext())) {
        advance()
        while (isDigit(peek())) {
          advance()
        }
        type = TomlToken.DATE
        if ((peek() == "T" || peek() == " ") && isDigit(peekNext())) {
          advance()
          while (isDigit(peek())) {
            advance()
          }
          type = TomlToken.DATETIME
        }
      }
    }

    if (peek() == ":" && isDigit(peekNext())) {
      // Local Time
      advance()
      while (isDigit(peek())) {
        advance()
      }
      if (peek() == ":" && isDigit(peekNext())) {
        // Local Time
        advance()
        while (isDigit(peek())) {
          advance()
        }
        if (type == TomlToken.INTEGER) {
          type = TomlToken.TIME
        }
      }
    }

    if (peek() == "." && isDigit(peekNext())) {
      advance()
      while (isDigit(peek())) {
        advance()
      }
      if (type == TomlToken.INTEGER) {
        type = TomlToken.FLOAT
      }
    }

    if (type == TomlToken.INTEGER || type == TomlToken.FLOAT) {
      addToken(type, Num.fromString(StringUtils.substring(_source, _start, _current)))
    } else {
      if (type == TomlToken.DATETIME) {
        if (peek() == "Z") {
          advance()
        } else if ((peek() == "+" || peek() == "-") && isDigit(peekNext())) {
          advance()
          while (isDigit(peek())) {
            advance()
          }
          if (peek() == ":" && isDigit(peekNext())) {
            // Local Time
            advance()
            while (isDigit(peek())) {
              advance()
            }
          }
        }
      }
      addToken(type, StringUtils.substring(_source, _start, _current))
    }
  }

  advance() {
    _current = _current + 1
    return _source[_current - 1]
  }

  peek() {
    if (isAtEnd()) {
      return "\n"
    }
    return _source[_current]
  }

  peekNext() {
    if (_current + 1 >= _source.count) {
      return "\0"
    }
    return _source[_current + 1]
  }

  addToken(type) {
    addToken(type, null)
  }

  addToken(type, literal) {
    var text = StringUtils.substring(_source, _start, _current)
    _tokens.add(Token.new(type, text, literal, _line))
  }

  isAtEnd() {
    return _current >= _source.count
  }


  match(expected) {
    if (isAtEnd()) {
      return false
    }
    if (_source[_current] != expected) {
      return false
    }

    _current = _current + 1
    return true
  }
}

class StringUtils {
  static substring(str, start, finish) {
    var output = ""
    for (i in start...finish) {
      output = output + str[i]
    }
    return output
  }

}
