import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random

import "./toml/toml" for Toml
import "./toml/toml-map-builder" for TomlMapBuilder


import "./gameover" for GameOverState
import "./util" for Box, AABB

import "./ecs/entity" for Entity
import "./ecs/component" for Component
import "./ecs/gamesystem" for GameSystem
import "./ecs/world" for World
import "./ecs/events" for Event, EventListener

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
     text = text + "position.y = 60 \n"

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

/*
 DEPRECIATED
class TileSystem is GameSystem {
  construct init(world) {
    super(world, [TileComponent])
  }

  update() {
      for (entity in entities) {
      }
    }
  }
}
*/

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

class TestEventSystem is GameSystem {
  construct init(world) {
    super(world, [])
    world.bus.subscribe(this, CollisionEvent)
  }

  update() {
    for (event in events) {
      System.print("%(event.e1) -> %(event.e2)")
    }
    clearEvents()
  }
}

class CollisionEvent is Event {
  construct new(e1, e2) {
    _e1 = e1
    _e2 = e2
  }
  e1 { _e1 }
  e2 { _e2 }
}

class CollisionSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent, ColliderComponent])
  }

  update() {
    var collisions = {}
    for (entity in entities) {
      var pos1 = entity.getComponent(PositionComponent)
      var col1 = entity.getComponent(ColliderComponent)

      for (nextEntity in entities) {
        if (nextEntity.id != entity.id) {
          var pos2 = nextEntity.getComponent(PositionComponent)
          var col2 = nextEntity.getComponent(ColliderComponent)
          if (AABB.isColliding(pos1.point, col1.box, pos2.point, col2.box)) {
              collisions[entity.id] = nextEntity.id
              world.bus.publish(CollisionEvent.new(entity.id, nextEntity.id))
          }
          // Check overlap
        }
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
      var render = entity.getComponent(RenderComponent)
      while (holePosition > 0 && sortedEntities[holePosition - 1].getComponent(RenderComponent).z > render.z) {
        sortedEntities[holePosition] = sortedEntities[holePosition - 1]
        holePosition = holePosition - 1
      }
      sortedEntities[holePosition] = entity
    }

    for (entity in sortedEntities) {
      var position = entity.getComponent(PositionComponent)
      var render = entity.getComponent(RenderComponent)
      for (obj in render.renderables) {
        obj.render(position)
      }
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
    // __world.addSystem(TileSystem)
    __world.addSystem(PhysicsSystem)
    __world.addSystem(CollisionSystem)
    __world.addSystem(TestEventSystem)
    __world.addRenderSystem(RenderSystem)
    __world.addComponentManager(PositionComponent)
    __world.addComponentManager(ColliderComponent)
    __world.addComponentManager(EnemyAIComponent)
    __world.addComponentManager(PlayerControlComponent)
    __world.addComponentManager(PhysicsComponent)
    __world.addComponentManager(RenderComponent)
    __world.addComponentManager(TileComponent)

    // Create player
    __player = __world.newEntity()
    __player.addComponents([PositionComponent, RenderComponent, PlayerControlComponent, PhysicsComponent, ColliderComponent])
    __player.getComponent(PositionComponent).x = Game.gameData["entities"][0]["position"]["x"]
    __player.getComponent(PositionComponent).y = Game.gameData["entities"][0]["position"]["y"]
    // __player.setComponent(RectComponent.new(__player.id, Color.blue, 16, 32))
    __player.setComponent(RenderComponent.new(__player.id, [ Rect.new(Color.blue, 16, 32)]))
    __player.getComponent(ColliderComponent).box = AABB.new(0, 0, 16, 32)


    // Create tilemap
    var tileSize = 8
    for (y in 0...(Canvas.height/ tileSize)) {
      for (x in 0...(Canvas.width/ tileSize)) {
        var tile = __world.newEntity()
        tile.addComponents([PositionComponent, RenderComponent, TileComponent])
        tile.setComponent(RenderComponent.new(__player.id, [Rect.new(Color.darkgray, tileSize, tileSize)], -1))
        tile.getComponent(PositionComponent).x = x * tileSize
        tile.getComponent(PositionComponent).y = y * tileSize
      }
    }

    // Enemy
    __enemy = __world.newEntity()
    __enemy.addComponents([PositionComponent, RenderComponent, EnemyAIComponent, ColliderComponent])
    __enemy.setComponent(RenderComponent.new(__enemy.id, [Rect.new(Yellow, 8,8)]))
    __enemy.getComponent(PositionComponent).y = 20
    __enemy.getComponent(ColliderComponent).box = AABB.new(0, 0, tileSize, tileSize)
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

