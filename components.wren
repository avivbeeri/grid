import "graphics" for Point, Color, Canvas
import "./ecs/component" for Component
import "./renderables" for Renderable

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
  point=(i) { _position = i }

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
    _type = "solid"
  }

  box { _box }
  box=(b) { _box = b }
  moved { _moved }
  moved=(b) { _moved = b }

  type { _type }
  type=(t) { _type = t }

  static Trigger { "trigger" }
  static Solid { "solid" }
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


class RenderComponent is Component {
  construct new(id) {
    super(id)
    setValues(null, 0)
  }

  construct new(id, renderable) {
    super(id)
    setValues(renderable, 0)
  }

  construct new(id, renderable, z) {
    super(id)
    setValues(renderable, z)
  }

  setValues(renderable, z) {
    _renderable = renderable
    _z = z
  }

  renderable { _renderable }
  z { _z }
}

