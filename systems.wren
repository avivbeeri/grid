import "input" for Keyboard
import "dome" for Process
import "graphics" for Canvas, Color, Point
import "./util" for AABB
import "./renderables" for Rect, Sprite

import "./ecs/gamesystem" for GameSystem
import "./ecs/events" for Event, EventListener

var FPS = 60 // Frames per second
var DT = (1/FPS) // Seconds per frame

import "./components" for
  ActiveComponent,
  PositionComponent,
  PhysicsComponent,
  PlayerControlComponent,
  TileComponent,
  ColliderComponent,
  EnemyAIComponent,
  RenderComponent

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
    super(world, [ActiveComponent, PositionComponent, PhysicsComponent])
  }

  update() {
    for (entity in entities) {
      var physics = entity.getComponent(PhysicsComponent)
      var acceleration = physics.acceleration
      var velocity = physics.velocity
      var position = entity.getComponent(PositionComponent)
      physics.pastPosition = position.point

      velocity.x = velocity.x + acceleration.x * DT
      velocity.y = velocity.y + acceleration.y * DT

      position.x = position.x + velocity.x * DT
      position.y = position.y + velocity.y * DT

      var collider = entity.getComponent(ColliderComponent)
      if (collider) {
        var diff = position.point - physics.pastPosition
        collider.moved = diff.x == 0 && diff.y == 0
      }
    }
  }
}

class TestEventSystem is GameSystem {
  construct init(world) {
    super(world, [])
    world.bus.subscribe(this, CollisionEvent)
  }

  update() {
    var doorId = world.getEntityByTag("door").id
    var playerId = world.getEntityByTag("player").id
    for (event in events) {
      if ((event.e1 == doorId && event.e2 == playerId) ||
          (event.e2 == doorId && event.e1 == playerId)) {
        world.bus.publish(CompletionEvent.new())
      }
    }
  }
}

class DetectionEvent is Event {
  construct new(level) {
    _level = level
  }
  level { _level }
}

class CompletionEvent is Event {
  construct new() {}
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
    super(world, [ActiveComponent, PositionComponent, ColliderComponent])
  }

  update() {
    var tiles = []
    var actors = []
    for (entity in entities) {
      if (entity.getComponent(TileComponent)) {
        tiles.add(entity)
      } else {
        actors.add(entity)
      }
    }
    for (entity in actors) {
      var col1 = entity.getComponent(ColliderComponent)
        var pos1 = entity.getComponent(PositionComponent)
        for (nextEntity in entities) {
          if (nextEntity.id != entity.id) {
            var pos2 = nextEntity.getComponent(PositionComponent)
            var col2 = nextEntity.getComponent(ColliderComponent)
            if (AABB.isColliding(pos1.point, col1.box, pos2.point, col2.box)) {

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
    super(world, [PositionComponent, EnemyAIComponent, ActiveComponent])
    world.bus.subscribe(this, CollisionEvent)
  }

  update() {
    var player = world.getEntityByTag("player")

    for (entity in entities) {
      var collided = false
      var position = entity.getComponent(PositionComponent)
      var collider = entity.getComponent(ColliderComponent)
      var ai = entity.getComponent(EnemyAIComponent)
      var physics = entity.getComponent(PhysicsComponent)

      for (event in events) {
        if ((event.e1 == player.id && event.e2 == entity.id) || (event.e1 == entity.id && event.e2 == player.id)) {
          collided = true
          if (!ai.deviation) {
            ai.deviation = position.point
            world.bus.publish(DetectionEvent.new("low"))
          }
        }
      }

      var velocity = physics.velocity
      physics.velocity.x = 0
      physics.velocity.y = 0
      if (!collided) {
        // Have we deviated?
        if (ai.deviation) {
          var diff = ai.deviation - position.point
          physics.velocity.x = sign(diff.x)
          physics.velocity.y = sign(diff.y)

          if (diff.x.abs < 1 && diff.y.abs < 1) {
            ai.deviation = null
          }
        } else {

          // else patrol
          ai.t = ai.t + 1
          if (ai.mode == "horizontal") {
            velocity.x = ai.dir * ai.speed
          }
          if (ai.mode == "vertical") {
            velocity.y = ai.dir * ai.speed
          }
          if (ai.t * ai.speed > ai.dist*8 ) {
            ai.t = 0
            ai.dir = -ai.dir
          }
        }
      } else {
          // get player entity
          var playerPosition = player.getComponent(PositionComponent).point
          var playerBox = player.getComponent(ColliderComponent).box.pos

          var x = (position.x+collider.box.pos.x) - (playerPosition.x + playerBox.x) + 3
          var y = (position.y + collider.box.pos.y) - (playerPosition.y + playerBox.y) - 8

          var e = 1
          if (x < -e) {
            x = -1
          } else if (x > e) {
            x = 1
          } else {
            x = 0
          }

          if (y < -e) {
            y = -1
          } else if (y > e) {
            y = 1
          } else {
            y = 0
          }

          if (x == 0 && y == 0) {
            ai.clock = ai.clock + 1
            if (ai.clock > 60) {
              world.bus.publish(DetectionEvent.new("high"))
            }
          } else {
            ai.clock = 0
          }
          physics.velocity.x = -x * 0.7
          physics.velocity.y = -y * 0.7
      }
      if (collided) {
    entity.getComponent(RenderComponent).renderable.children[0].state = "active"
      } else {
    entity.getComponent(RenderComponent).renderable.children[0].state = "normal"
      }
      physics.velocity.x = physics.velocity.x * FPS
      physics.velocity.y = physics.velocity.y * FPS
    }
  }

  sign(x) {
    if (x < 0) {
      return -1
    }
    if (x > 0) {
      return 1
    }
    return 0
  }
}

class PlayerControlSystem is GameSystem {
  construct init(world) {
    super(world, [PlayerControlComponent, PhysicsComponent])
  }

  update() {
    for (entity in entities) {
      var velocity = entity.getComponent(PhysicsComponent).velocity
      var sprite = entity.getComponent(RenderComponent).renderable
      var x = 0
      var y = 0

      var stand = 0
      sprite.state = "standing"

      if (Keyboard.isKeyDown("escape")) {
        Process.exit()
      }
      if (Keyboard.isKeyDown("left")) {
        x = x - 1
        stand = 48
        sprite.state = "running-left"
      } else if (Keyboard.isKeyDown("right")) {
        x = x + 1
        stand = 16
        sprite.state = "running-right"
      } else if (Keyboard.isKeyDown("up")) {
        y = y - 1
        stand = 32
        sprite.state = "running-up"
      } else if (Keyboard.isKeyDown("down")) {
        y = y + 1
        stand = 0
        sprite.state = "running-down"
      }

      if (Keyboard.isKeyDown("space")) {
      }

      velocity.x = x * FPS
      velocity.y = y * FPS
    }
  }
}

class ScrollSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent])
    _screenCache = null
    _firstRun = true
  }

  clearEntityCache() {
    super.clearEntityCache()
    _screenCache = null
  }

  hash(x, y) {
    var a = x
    var b = y
    return a >= b ? a * a + a + b : a + b * b
  }

  update() {
    if (!_screenCache) {
      _screenCache = {}
      for (entity in entities) {
        var position = entity.getComponent(PositionComponent).point
        var screenX = (position.x / Canvas.width).floor
        var screenY = (position.y / Canvas.height).floor
        if (!_screenCache[hash(screenX, screenY)]) {
          _screenCache[hash(screenX, screenY)] = []
        }
        _screenCache[hash(screenX, screenY)].add(entity)
      }
    }

    var player = world.getEntityByTag("player").getComponent(PositionComponent).point
    var playerPast = world.getEntityByTag("player").getComponent(PhysicsComponent).pastPosition
    var screenX = (player.x / Canvas.width).floor
    var screenY = (player.y / Canvas.height).floor
    var oldScreenX = (playerPast.x / Canvas.width).floor
    var oldScreenY = (playerPast.y / Canvas.height).floor

    if (_firstRun || oldScreenX != screenX || oldScreenY != screenY) {
      for (entity in _screenCache[hash(oldScreenX, oldScreenY)]) {
        entity.removeComponent(ActiveComponent)
      }
      for (entity in _screenCache[hash(screenX, screenY)]) {
        entity.addComponents([ActiveComponent])
      }
      world.clearSystemCaches()
      _firstRun = false
    }
  }
}

class RenderableUpdateSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent, RenderComponent, ActiveComponent])
  }

  update() {
    for (entity in entities) {
      entity.getComponent(RenderComponent).renderable.update()
    }
  }
}

class RenderSystem is GameSystem {
  min(a, b) {
    return a < b ? a : b
  }
  max(a, b) {
    return a > b ? a : b
  }
  construct init(world) {
    super(world, [PositionComponent, RenderComponent, ActiveComponent])
    _updated = true
    _layers = {}
    _minLayer = 0
    _maxLayer = 0
  }
  update(dt) {
    Canvas.cls(Color.black)

    var layers = _layers
    if (_updated) {
      _updated = false
      _minLayer = 0
      _maxLayer = 0
      for (entity in entities) {
        var stack = []
        var renderable = entity.getComponent(RenderComponent).renderable
        var point = Point.new(0, 0)
        stack.add({ "r": renderable, "offset": point, "entity": entity })
        while (stack.count > 0) {
          var obj = stack.removeAt(-1)

          var r = obj["r"]
          var z = r.z
          _minLayer = min(_minLayer, z)
          _maxLayer = max(_maxLayer, z)
          var offset = obj["offset"]

          if (r.children.count == 0) {
            if (!layers[z]) {
              layers[z] = []
            }
            layers[z].add(obj)
          } else {
            for (child in r.children) {
              stack.add({ "r": child, "offset": offset, "entity": entity})
            }
          }
        }
      }
    }

    var player = world.getEntityByTag("player").getComponent(PositionComponent).point
    var screenX = (player.x / Canvas.width).floor
    var screenY = (player.y / Canvas.height).floor
    var cameraOffset = Point.new(screenX * -40 * 8, screenY * -30 * 8)

    for (i in _minLayer.._maxLayer) {
      if (layers[i]) {
        for (obj in layers[i]) {
          var entity = obj["entity"]
          var position = entity.getComponent(PositionComponent).point
          var physics = entity.getComponent(PhysicsComponent)
          var velocity = Point.new(0, 0)
          if (physics) {
            velocity.x = physics.velocity.x * dt * (1/1000)
            velocity.y = physics.velocity.y * dt * (1/1000)
          }
          obj["r"].render(dt, obj["offset"] + position + cameraOffset + velocity)
        }
      }
    }
  }
  clearEntityCache() {
    super.clearEntityCache()
    _layers = {}
    _updated = true
  }
}


class ColliderRenderSystem is GameSystem {
  construct init(world) {
    super(world, [ActiveComponent, PositionComponent, ColliderComponent])
  }

  update() {
    var player = world.getEntityByTag("player").getComponent(PositionComponent).point
    var screenX = (player.x / Canvas.width).floor
    var screenY = (player.y / Canvas.height).floor
    var cameraOffset = Point.new(screenX * -40 * 8, screenY * -30 * 8)
    for (entity in entities) {
      var position = entity.getComponent(PositionComponent).point
      var collider = entity.getComponent(ColliderComponent).box

      var start = position + collider.pos + cameraOffset

      Canvas.rectfill(start.x, start.y, collider.size.x, collider.size.y, Color.new(255, 0, 0, 255*0.10))
    }

  }
}

class ColliderResolutionSystem is GameSystem {
  construct init(world) {
    super(world, [])
    world.bus.subscribe(this, CollisionEvent)
  }

  update() {
    var tiles = {}
    var actors = {}
    for (event in events) {

      var entity1 = world.getEntityById(event.e1)
      var position1 = entity1.getComponent(PositionComponent)
      var collider1 = entity1.getComponent(ColliderComponent)
      var physics1 = entity1.getComponent(PhysicsComponent)

      var entity2 = world.getEntityById(event.e2)
      var position2 = entity2.getComponent(PositionComponent)
      var collider2 = entity2.getComponent(ColliderComponent)
      var physics2 = entity2.getComponent(PhysicsComponent)
      if (collider1.type == ColliderComponent.Solid) {
        if (collider2.type == ColliderComponent.Solid) {
          position1.point = physics1.pastPosition

        }
      }
    }
    /*
    for (entity in actors) {
      var position = entity.getComponent(PositionComponent).point
      var collider = entity.getComponent(ColliderComponent).box
      position.point =

    }
    */

  }
}
