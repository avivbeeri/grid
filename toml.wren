class Toml {
  static run(source) {
    var scanner = TomlScanner.new(source)
    var tokens = scanner.scanTokens()

    for (token in tokens) {
      System.print(token)
    }
  }
  
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
  static DATE { "DATE" }
  static TIME { "TIME" }
  static DATETIME { "DATETIME" }

  static TRUE { "TRUE" }
  static FALSE { "FALSE" }

  static IDENTIFIER { "IDENTIFIER" }
}

class Token {
  construct new(type, lexeme, literal, line) {
    _type = type
    _lexeme = lexeme
    _literal = literal
    _line = line
  }

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
