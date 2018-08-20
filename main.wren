import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random

import "./toml/toml" for Toml
import "./toml/toml-map-builder" for TomlMapBuilder


import "./gameover" for GameOverState
import "./util" for Box

import "./ecs/entity" for Entity
import "./ecs/component" for Component
import "./ecs/gamesystem" for GameSystem
import "./ecs/world" for World

var Yellow = Color.rgb(255, 162, 00, 00)


// -------------------------
// ------- GAME CODE -------
// -------------------------
class Game {
  static gameData { __gameData }
  static init() {
    __state = MainGame

     var text = "[[entities]] \n"
     //text = text + "basic2.broken = \"Hello \nworld\" \n"
     // text = text + "test.broken = 'hello"
     text = text + "position.x = 20 \n"
     text = text + "position.y = 20 \n"

    var document = Toml.run(text)
    __gameData = TomlMapBuilder.new(document).build()
    System.print(__gameData)

    __state.init()

  }
  static update() {
    __state.update()
    if (__state.next) {
      __state = __state.next
      __state.init()
    }
  }
  static draw(dt) {
    __state.draw(dt)
  }
}

class PositionComponent is Component {
  construct new(id) {
    super(id)
    _position = Point.new(0, 0)
  }
  construct new(id, x, y) {
    super(id)
    _position = Point.new(x, y)
  }

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
  }
  velocity { _velocity }
  acceleration { _acceleration }
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
class TileSystem is GameSystem {
  construct init(world) {
    super(world, [TileComponent, RectComponent])
    _t = 0
  }

  update() {
    _t = _t + 1
    if (_t > 60) {
      _t = 0
      for (entity in entities) {
        var rect = entity.getComponent(RectComponent)
        // rect.setValues(rect.color == Color.white ? Color.black : Color.white, 8, 8)
      }
    }
  }
}

class PhysicsSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent, PhysicsComponent])
  }

  update() {
    for (entity in entities) {
      var physics = entity.getComponent(PhysicsComponent)
      var acceleration = physics.acceleration
      var velocity = physics.velocity
      var position = entity.getComponent(PositionComponent)

      position.x = position.x + velocity.x
      position.y = position.y + velocity.y
    }
  }
}

class EnemyAISystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent, EnemyAIComponent])
  }

  update() {
    for (entity in entities) {
      var position = entity.getComponent(PositionComponent)
      var ai = entity.getComponent(EnemyAIComponent)
      if (ai.mode == "horizontal") {
        position.x = position.x + ai.dir
        if ((ai.dir > 0 && position.x >= Canvas.width-8) || (ai.dir < 1 && position.x <= 0)) {
          ai.mode = "vertical"
        }
      } else if (ai.mode == "vertical") {
        position.y = position.y + 1
        ai.t = ai.t + 1
        if (ai.t >= 32) {
          ai.mode = "horizontal"
          ai.dir = -ai.dir
          ai.t = 0
        }
        if (position.y >= Canvas.height - 8) {
          ai.dir = -ai.dir
          ai.t = 0
          ai.mode = "reverse"
        }
      } else if (ai.mode == "reverse") {
        position.y = position.y - 1
        if (position.y <= 0) {
          ai.mode = "horizontal"
        }
      }
    }
  }
}

class PlayerControlSystem is GameSystem {
  construct init(world) {
    super(world, [PlayerControlComponent, PhysicsComponent])
  }

  update() {
    for (entity in entities) {
      var velocity = entity.getComponent(PhysicsComponent).velocity
      var x = 0
      var y = 0

      if (Keyboard.isKeyDown("left")) {
        x = -1
      } else if (Keyboard.isKeyDown("right")) {
        x = 1
      } else if (Keyboard.isKeyDown("up")) {
        y = -1
      } else if (Keyboard.isKeyDown("down")) {
        y = 1
      }
      if (Keyboard.isKeyDown("space")) {
      }

      velocity.x = x
      velocity.y = y
    }
  }
}

class ScrollSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent])
  }
  update() {
    for (entity in entities) {
      var position = entity.getComponent(PositionComponent)
      position.x = (position.x + 1) % Canvas.width
      if (position.x > Canvas.width/2) {
      }
    }
  }
}

class RenderComponent is Component {
  construct new(id) {
    super(id)
    setRenderFunction(Fn.new {|entity|

    })
  }

  construct new(id, fn) {
    super(id)
    setRenderFunction(fn)
  }

  setRenderFunction(fn) {
    _fn = fn
  }

  render() {
    _fn.call(this)
  }
}

class RectComponent is Component {
  construct new(id) {
    super(id)
    setValues(Color.white, 5, 5, 0)
  }

  construct new(id, color) {
    super(id)
    setValues(color, 5, 5, 0)
  }

  construct new(id, color, w, h) {
    super(id)
    setValues(color, w, h, 0)
  }

  construct new(id, color, w, h, z) {
    super(id)
    setValues(color, w, h, z)
  }

  setValues(color, w, h, z) {
    _color = color
    _width = w
    _height = h
    _z = z
  }

  color { _color }
  width { _width }
  height { _height }
  z { _z }
}

class RenderSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent, RenderComponent])
  }
  update() {
    Canvas.cls()
    var sortedEntities = entities[0..-1]

    // Insertion sort the entities
    // TODO: We should cache this
    for (i in 0...sortedEntities.count) {
      var holePosition = i
      var entity = sortedEntities[i]
      var rect = entity.getComponent(RectComponent)
      while (holePosition > 0 && sortedEntities[holePosition - 1].getComponent(RectComponent).z > rect.z) {
        sortedEntities[holePosition] = sortedEntities[holePosition - 1]
        holePosition = holePosition - 1
      }
      sortedEntities[holePosition] = entity
    }

    for (entity in sortedEntities) {
      var position = entity.getComponent(PositionComponent)
      var rect = entity.getComponent(RectComponent)
      Canvas.rectfill(position.x, position.y, rect.width, rect.height, rect.color)
    }
  }
}

class MainGame {
  static next { __next}

  static init() {
    __next = null
    __t = 0

    // World system setup
    __world = World.new()
    __world.addSystem(PlayerControlSystem)
    __world.addSystem(EnemyAISystem)
    __world.addSystem(TileSystem)
    __world.addSystem(PhysicsSystem)
    __world.addRenderSystem(RenderSystem)
    __world.addComponentManager(PositionComponent)
    __world.addComponentManager(EnemyAIComponent)
    __world.addComponentManager(PlayerControlComponent)
    __world.addComponentManager(PhysicsComponent)
    __world.addComponentManager(RectComponent)
    __world.addComponentManager(TileComponent)

    // Create player
    __player = __world.newEntity()
    __player.addComponents([PositionComponent, RenderComponent, PlayerControlComponent, PhysicsComponent])
    __player.getComponent(PositionComponent).x = Game.gameData["entities"][0]["position"]["x"]
    __player.getComponent(PositionComponent).y = Game.gameData["entities"][0]["position"]["y"]
    __player.setComponent(RectComponent.new(__player.id, Color.blue, 16, 32))
    var playerRender =
    __player.setComponent(RenderComponent.new(__player.id, Fn.new({|entity|
      var position = entity.getComponent(PositionComponent)
      var rect = entity.getComponent(RectComponent)
      Canvas.rectfill(position.x, position.y, 16, 32, Color.blue)
    })))


    // Create tilemap
    var tileSize = 8
    for (y in 0...(Canvas.height/ tileSize)) {
      for (x in 0...(Canvas.width/ tileSize)) {
        var tile = __world.newEntity()
        tile.addComponents([PositionComponent, RectComponent, TileComponent])
        tile.setComponent(RectComponent.new(__player.id, Color.black, tileSize, tileSize, -1))
        tile.getComponent(PositionComponent).x = x * tileSize
        tile.getComponent(PositionComponent).y = y * tileSize
      }
    }

    // Enemy
    __enemy = __world.newEntity()
    __enemy.addComponents([PositionComponent, RectComponent, EnemyAIComponent])
    __enemy.setComponent(RectComponent.new(__enemy.id, Yellow, 8,8))
    __enemy.getComponent(PositionComponent).y = 50
  }

  static update() {
    __t = __t + 1
    __world.update()
  }

  static draw(dt) {
    __world.render()
    Canvas.ellipsefill( 20, 20, 70, 40, Color.green)
  }
}

