import "./toml/toml-token" for Token, TomlToken
import "./toml/toml-types" for TomlType
import "./toml/toml-ast" for TomlArray, TomlTable, TomlArrayTable, TomlDocument, TomlKey, TomlUnary, TomlLiteral,TomlValue, TomlKeyValuePair, TomlInlineTable

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
    var currentTable = document[0]
    while (!isAtEnd()) {
      if (match([TomlToken.LEFT_BRACKET])) {
        if (match([TomlToken.LEFT_BRACKET])) {
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
    var key = TomlKey.new(keyPath())
    consume(TomlToken.EQUALS, "Expected EQUALS after a key")
    return TomlKeyValuePair.new(key, value())
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
      var table = TomlInlineTable.new()
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
