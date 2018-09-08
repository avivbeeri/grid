import "graphics" for Point, Color, Canvas
import "./ecs/component" for Component

class PositionComponent is Component {
  construct new(id) {
    super(id)
    _position = Point.new(0, 0)
  }
  construct new(id, x, y) {
    super(id)
    _position = Point.new(x, y)
  }

  point { _position }

  x { _position.x }
  y { _position.y }
  x=(i) { _position = Point.new(i, _position.y)}
  y=(i) { _position = Point.new(_position.x, i)}
}

class PhysicsComponent is Component {
  construct new(id) {
    super(id)
    _velocity = Point.new(0, 0)
    _acceleration = Point.new(0, 0)
    _pastPosition = Point.new(0, 0)
  }
  velocity { _velocity }
  acceleration { _acceleration }
  pastPosition { _pastPosition }
  pastPosition=(p) { _pastPosition = p }
}

class PlayerControlComponent is Component {
  construct new(id) {
    super(id)
  }
}
class TileComponent is Component {
  construct new(id) {
    super(id)
  }
}

class ColliderComponent is Component {
  construct new(id) {
    super(id)
  }

  box { _box }
  box=(b) { _box = b }
}

class EnemyAIComponent is Component {
  construct new(id) {
    super(id)
    _mode = "horizontal"
    _t = 0
    _dir = 1
  }
  mode { _mode }
  mode=(v) { _mode = v }
  t { _t }
  t=(v) { _t = v }
  dir { _dir }
  dir=(v) { _dir = v }
}

class Renderable {
  render(position) {}
}

class RenderComponent is Component {
  construct new(id) {
    super(id)
    setValues([], 0)
  }

  construct new(id, renderables) {
    super(id)
    setValues(renderables, 0)
  }

  construct new(id, renderables, z) {
    super(id)
    setValues(renderables, z)
  }

  setValues(renderables, z) {
    if (renderables.where{|r| !(r is Renderable)}.count > 0) {
      Fiber.abort("Tried to pass non-renderables")
    }
    _renderables = renderables
    _z = z
  }

  renderables { _renderables }
  z { _z }
}

class Sprite is Renderable {
  construct new(sprite) {
    _image = sprite
    _x = 0
    _y = 0
    _w = _image.width
    _h = _image.height
  }
  render(position) {
    _image.drawArea(_x, _y, _w, _h, position.x, position.y)
  }

  setSrc(x, y, w, h) {
    _x = x
    _y = y
    _w = w
    _h = h
  }

  x=(v) { _x = v }
}

class Rect is Renderable {
  construct new() {
    setValues(Color.white, 5, 5)
  }

  construct new(color) {
    setValues(color, 5, 5)
  }

  construct new(color, w, h) {
    setValues(color, w, h)
  }

  setValues(color, w, h) {
    _color = color
    _width = w
    _height = h
  }

  render(position) {
    Canvas.rectfill(position.x, position.y, width, height, color)
  }

  color { _color }
  width { _width }
  height { _height }

}
