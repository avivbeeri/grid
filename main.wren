import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random

import "./toml" for Toml

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
  static init() {
    __state = MainGame
    __state.init()

    var document = Toml.run("t = { work = 0x42, play = \"\"\"Im a string. \\U00660000You ca\nn quote me\\\" \"\"\" }\n[[config]]\ndot-stuff = 'Hello world'\nnewline     =     [true, false]")
    for (table in document.tables) {
      System.print("[%(table.key)]")
      for (pair in table.pairs) {
        System.print("%(pair.key): %(pair.value)")
      }
    }
    for (table in document.arrayTables) {
      System.print("[[%(table.key)]]")
      for (pair in table.pairs) {
        System.print("%(pair.key): %(pair.value)")
      }
    }
    System.print("-- END --")
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
    super(world, [PositionComponent, PlayerControlComponent])
  }

  update() {
    for (entity in entities) {
      var position = entity.getComponent(PositionComponent)
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

      position.x = position.x + x
      position.y = position.y + y
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

class RectComponent is Component {
  construct new(id) {
    super(id)
    setValues(Color.white, 5, 5)
  }

  construct new(id, color) {
    super(id)
    setValues(color, 5, 5)
  }

  construct new(id, color, w, h) {
    super(id)
    _color = color
    _width = w
    _height = h
  }

  setValues(color, w, h) {
    _color = color
    _width = w
    _height = h
  }

  color { _color }
  width { _width }
  height { _height }
}

class RenderSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent, RectComponent])
  }
  update() {
    Canvas.cls()
    for (entity in entities) {
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
    __world.addRenderSystem(RenderSystem)
    __world.addComponentManager(PositionComponent)
    __world.addComponentManager(EnemyAIComponent)
    __world.addComponentManager(PlayerControlComponent)
    __world.addComponentManager(RectComponent)
    __world.addComponentManager(TileComponent)

    // Create player
    __player = __world.newEntity()
    __player.addComponents([PositionComponent, RectComponent, PlayerControlComponent])
    __player.setComponent(RectComponent.new(__player.id, Color.blue, 16, 32))

    for (y in 0...(Canvas.height/8)) {
      for (x in 0...(Canvas.width/8)) {
        var tile = __world.newEntity()
        tile.addComponents([PositionComponent, RectComponent, TileComponent])
        tile.setComponent(RectComponent.new(__player.id, Color.white, 8, 8))
        tile.getComponent(PositionComponent).x = x * 8
        tile.getComponent(PositionComponent).y = y * 8
      }
    }
    // Create player

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
  }
}

