import "graphics" for Point

class AABB {
  construct new(x, y, w, h) {
    _pos = Point.new(x, y)
    _size = Point.new(w, h)
  }
  construct new(pos, size) {
    _pos = pos
    _size = size
  }

  pos { _pos }
  size { _size }

  static isColliding(pos1, aabb1, pos2, aabb2) {

   var box1 = AABB.new(aabb1.pos + pos1, aabb1.size)
   var box2 = AABB.new(aabb2.pos + pos2, aabb2.size)
   return box1.pos.x < box2.pos.x + box2.size.x &&
     box1.pos.x + box1.size.x > box2.pos.x &&
     box1.pos.y < box2.pos.y + box2.size.y &&
     box1.pos.y + box1.size.y > box2.pos.y
  }

}

// Consider moving Box to "graphics"
class Box {
  construct new(x1, y1, x2, y2) {
    _p1 = Point.new(x1, y1)
    _p2 = Point.new(x2, y2)
  }

  x1 { _p1.x }
  y1 { _p1.y }
  x2 { _p2.x }
  y2 { _p2.y }

  static colliding(o1, o2) {
    var box1 = Box.new(o1.x, o1.y, o1.x + o1.w, o1.y+o1.h)
    var box2 = Box.new(o2.x, o2.y, o2.x + o2.w, o2.y+o2.h)
    return box1.x1 < box2.x2 &&
      box1.x2 > box2.x1 &&
      box1.y1 < box2.y2 &&
      box1.y2 > box2.y1
  }
}

class Utils {

  /*
     Returns true if the given ClassObject is a descendant of
     superClass but is not equal to superClass
   */
  static isClassDescendant(candidate, superClass) {
    if (candidate is Class && superClass is Class) {
      var type = candidate
      while (type != Object) {
        type = type.supertype
        if (type == superClass) {
          return true
        }
      }
    } else {
      Fiber.abort("Trying to check if %(candidate) is descendant of %(superClass)")
    }
    return false
  }

}
