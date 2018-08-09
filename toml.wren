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
  static STRING { 3 }
  static INTEGER { 4 }
  static FLOAT { 5 }
  static DATE { 6 }

  static TRUE { 7 }
  static FALSE { 8 }

  static EQUALS { 9 }
  static COMMA { 10 }
  static DOT { 11 }
  static EOF { 12 }
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
    } else {
      // Handle keys, values including booleans
      
    }

  }

  advance() {
    _current = _current + 1  
    return source[_current - 1]
  }

  isAtEnd() {
    return _current >= _source.count
  }
  
  
}
