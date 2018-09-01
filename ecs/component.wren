import "./util" for Utils

class Component {
  construct new(id) {
    _id = id
  }

  id { _id }

  /*
     Returns true if the given ClassObject is a descendant of
     Component but not Component
   */
  static isComponentType(classObject) {
    return Utils.isClassDescendant(classObject, Component)
  }

  static getSubtype(classObject) {
    var type = classObject
    var previous = classObject
    while (type != Component) {
      previous = type
      type = type.supertype
    }
    return previous
  }
}

