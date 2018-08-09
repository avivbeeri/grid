class Component {
  construct new(id) {
    _id = id
  }

  id { _id }

  static isComponentType(classObject) {
    if (classObject is Class) {
      var type = classObject
      while (type != Object) {
        type = type.supertype
        if (type == Component) {
          return true
        }
      }
    } 
    return false
  }
}
