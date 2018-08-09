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
  static LEFT_BRACKET { 1 }
  static RIGHT_BRACKET { 2 }
  static BASIC_STRING { 3 }
  static INTEGER { 4 }
  static FLOAT { 5 }
  static DATE { 6 }

  static TRUE { 7 }
  static FALSE { 8 }

  static EQUALS { 9 }
  static COMMA { 10 }
  static DOT { 11 }
  static EOF { 12 }
  static MINUS { 13 }
}

class Token {
  construct new(type, lexeme, literal, line) {
    _type = type
    _lexeme = lexeme
    _literal = literal
    _line = line
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

    _tokens.add(Token.new(TomlToken.EOF, "", null, line)
    return _tokens
  }

  scanToken() {
    var char = advance()
    if (char == "[") {
      addToken(TomlToken.LEFT_BRACKET) 
    } else if (char == "]") {
      addToken(TomlToken.RIGHT_BRACKET) 
    } else if (char == "=") {
      addToken(TomlToken.EQUALS) 
    } else if (char == ".") {
      addToken(TomlToken.DOT) 
    } else if (char == ",") {
      addToken(TomlToken.COMMA) 
    } else if (char == "-") {
      addToken(TomlToken.MINUS) 
    } else if (char == " " || char == "\r" || char == "\t") {
      // Ignore and move forward
    } else if (char == "\n") {
      _line = _line + 1
    } else if (char == "#") {
      while (peek() != "\n" && !isAtEnd()) {
        advance()
      }
    } else if (char == "\"") {
      string()
    } else {
      // Handle keys, values including booleans
      Fiber.abort("Lexing error")
    }

  }

  string() {
    // TODO: Support non-basic and multi-line strings
    while (peek() != "\"" && !isAtEnd()) {
      if (peek() == "\n") {
        Fiber.abort("multi-line string")
      }
      advance()
    }

    if (isAtEnd()) {
      Fiber.abort("Unterminated string")
      return
    }
    advance()
    var value = StringUtils.substring(source, _start + 1, _current - 1)
    // TODO: Unescape values
    addToken(TomlToken.BASIC_STRING, value)
  }

  advance() {
    _current = _current + 1  
    return source[_current - 1]
  }

  peek() {
    if (isAtEnd()) {
      return "\n"
    }
    return _source[_current]
  }

  addToken(type) {
    addToken(type, null)
  }

  addToken(type, literal) {
    var text = StringUtils.substring(source, _start, _current))
    _tokens.add(Token.new(type, text, literal, _line))
  }

  isAtEnd() {
    return _current >= _source.count
  }


  match(expected) {
    if (isAtEnd()) {
      return false
    }
    if (source[_current] != expected) {
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
