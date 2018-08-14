import "./toml/toml-parser" for TomlParser
import "./toml/toml-scanner" for TomlScanner

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
