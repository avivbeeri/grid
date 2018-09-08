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

