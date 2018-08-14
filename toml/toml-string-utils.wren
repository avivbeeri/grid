class StringUtils {
  static substring(str, start, finish) {
    var output = ""
    for (i in start...finish) {
      output = output + str[i]
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
         if (EscapeChars[escapeChar] is Num) {
           i = i + 1
           var code = ""
           for (j in 0...EscapeChars[escapeChar]) {
             code = code + value[i+j]
           }
           System.print("Code: %(code)")
           outputValue = outputValue + String.fromCodePoint(Num.fromString(code))
           i = i + EscapeChars[escapeChar] - 1
         } else {
           outputValue = outputValue + EscapeChars[value[i]]
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
