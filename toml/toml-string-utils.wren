class StringUtils {
  static substring(str, start, finish) {
    var output = ""
    for (i in start...finish) {
      output = output + str[i]
    }
    return output
  }

  static normaliseNewLines(str) {
    var output = ""
    var finish = str.count
    var i = 0
    while (i < finish) {
      var char = str[i]
      var next = (i+1) < finish ? str[i+1] : "\0"
      if (char == "\r" && next == "\n") {
        i = i + 1
      } else {
        output = output + char
        i = i + 1
      }
    }
    return output
  }

  static unescape(value) {

    var EscapeChars = StringUtils.EscapeChars
    var outputValue = ""
    var i = 0
    while (i < value.count) {
      if (value[i] == "\\") {
         i = i + 1
         var escapeChar = value[i]
         if (EscapeChars.containsKey(escapeChar)) {
           if (EscapeChars[escapeChar] is Num) {
             // Handle the \u and \U unicode escapes
             i = i + 1
             var code = ""
             for (j in 0...EscapeChars[escapeChar]) {
               code = code + value[i+j]
             }
             outputValue = outputValue + String.fromCodePoint(Num.fromString(code))
             i = i + EscapeChars[escapeChar] - 1
           } else {
             outputValue = outputValue + EscapeChars[escapeChar]
           }
         } else {
           // Invalid escape sequence - We don't blow up here as that choice is for the client
           outputValue = outputValue + "\\" + value[i]
         }
      } else {
        outputValue = outputValue + value[i]
      }
      i = i + 1
    }
    return outputValue
  }

  static EscapeChars {
    return {
      "b": "\b",
      "t": "\t",
      "n": "\n",
      "f": "\f",
      "r": "\r",
      "\"": "\"",
      "\\": "\\",
      "u": 4,
      "U": 8
    }
  }

}
