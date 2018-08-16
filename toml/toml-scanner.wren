import "./toml/toml-token" for Token, TomlToken
import "./toml/toml-string-utils" for StringUtils

class TomlScanner {
  construct new(source) {
    _tokens = []
    _source = StringUtils.normaliseNewLines(source)

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
    if (char == "\r") {
      Fiber.abort("Couldn't strip \\r")
    }
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
      number(char)
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
    var stringType = type == TomlToken.BASIC_STRING ? "basic" : "literal"
    var multiline = false
    var quoteSize = 1

    if (peek() == quoteType) {
      advance()
      consume(quoteType, "Expected %(quoteType) to initiate string")

      type = stringType == "basic" ? TomlToken.MULTILINE_BASIC_STRING : TomlToken.MULTILINE_LITERAL_STRING
      multiline = true
      quoteSize = 3
    }
    // TOML allows the first \n to be ignored in multiline strings
    while (peek() != quoteType && !isAtEnd()) {
      advance()
    }

    /*
    if (isAtEnd()) {
      Fiber.abort("Unterminated string")
      return
    }
    */

    consume(quoteType, "Unterminated string")
    if (multiline) {
      consume(quoteType, "Expected %(quoteType) to terminate string")
      consume(quoteType, "Expected %(quoteType) to terminate string")
    }
    var value = StringUtils.substring(_source, _start+quoteSize, _current - quoteSize)
    if (!multiline) {
      value = singleLineString(stringType, value)
    } else {
      value = multilineString(stringType, value)
    }

    var outputValue = stringType == "basic" ? StringUtils.unescape(value) : value
    addToken(type, outputValue)
  }

  singleLineString(stringType, str) {
    var i = 0
    var out = ""
    while (i < str.count) {
      var char = str[i]
      var nextChar = (i + 1) < str.count ? str[i+1] : "\n"
      if (char == "\n") {
        Fiber.abort("%(stringType) string must be on a single line")
      }
      if (char == "\\") {
        if (stringType == "basic" && !StringUtils.EscapeChars.containsKey(nextChar)) {
          Fiber.abort("\\%(nextChar): Invalid escape sequence in string")
        }
      }
      out = out + char
      i = i + 1
    }
    return out
  }

  multilineString(stringType, str) {
    var i = 0
    var out = ""
    var advance = true
    while (i < str.count) {
      var char = str[i]
      var nextChar = (i + 1) < str.count ? str[i+1] : "\n"
      if (!isWhitespace(char) && !isNewline(char)) {
        advance = false
      }
      if (!advance) {
        if (char == "\\") {
          if (isWhitespace(nextChar) || isNewline(nextChar)) {
            advance = true
          } else if (stringType == "basic" && !StringUtils.EscapeChars.containsKey(nextChar)) {
            Fiber.abort("'%(char)': Invalid escape sequence in string")
          }
        }
        if (!advance) {
          out = out + char
        }
      }
      i = i + 1
    }
    return out

      /*
      if (peek() == "\\" && stringType == "basic") {
        if (StringUtils.EscapeChars.containsKey(peekNext()) || isWhitespace(peekNext()) || isNewline(peekNext())) {
          advance()
        } else if (size == 1) {
          var value = StringUtils.substring(_source, _start + size + trim, _current)
          System.print(peekNext())
          Fiber.abort("%(value): Invalid escape sequence in string")
        }
      }
      */
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

  isWhitespace(char) {
    return char == " " || char == "\t"
  }
  isNewline(char) {
    return char == "\n"
  }

  number(char) {
    // TODO: Split into Number and Date based on number of digits
    // Enforce RFC3339 Date / Time formats
    if (char == "0" && (peek() == "x" || peek() == "b" || peek() == "o")) advance()
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
      if (match("e") || match("E")) {
        if (match("-") || match("+")) {
          while (isDigit(peek())) {
            advance()
          }
          type = TomlToken.FLOAT
        } else {
          Fiber.abort("Invalid float exponent")
        }
      }

      var numString = StringUtils.substring(_source, _start, _current)
      var value = Num.fromString(numString)

      if (numString.count > 1) {
        if (numString[1] == "o") {
          numString = StringUtils.substring(numString, 2, numString.count)
          var totalPlaces = numString.count
          var result = 0
          for (i in 1..totalPlaces) {
            var number = Num.fromString(numString[-i])
            if (number < 0 || number > 7) {
              Fiber.abort("%(numString): Invalid octal value")
            }
            var place = number * (8.pow(i-1))
            result = result + place
          }
          value = result
        } else if (numString[1] == "b") {
          numString = StringUtils.substring(numString, 2, numString.count)
          var totalPlaces = numString.count
          var result = 0
          for (i in 1..totalPlaces) {
            var number = Num.fromString(numString[-i])
            if (number < 0 || number > 1) {
              Fiber.abort("%(numString): Invalid binary value")
            }
            var place = number * (2.pow(i-1))
            result = result + place
          }
          value = result
        } else {
          Fiber.abort("%(numString): Unsupported base prefix")
        }
      }

      addToken(type, value)
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

  consume(expected, message) {
    if (match(expected)) {
      return true
    }
    Fiber.abort(message)
  }
}
