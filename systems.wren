import "input" for Keyboard
import "graphics" for Canvas, Color, Point
import "./util" for AABB

import "./ecs/gamesystem" for GameSystem
import "./ecs/events" for Event, EventListener

import "./components" for
  PositionComponent,
  PhysicsComponent,
  PlayerControlComponent,
  TileComponent,
  ColliderComponent,
  EnemyAIComponent,
  RenderComponent,
  Renderable,
  Rect

var Yellow = Color.rgb(255, 162, 00, 00)
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
    world.bus.subscribe(this, CollisionEvent)
  }

  update() {

    for (entity in entities) {
      var collided = false
      for (event in events) {
        if (event.e1 == entity.id || event.e2 == entity.id) {
          collided = true
        }
      }
      var position = entity.getComponent(PositionComponent)
      var ai = entity.getComponent(EnemyAIComponent)
      if (!collided) {
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
      } else {

      }
      var renderableComponent = entity.getComponent(RenderComponent)
      for (obj in renderableComponent.renderables) {
        if (obj is Rect) {
          if (collided) {
          obj.setValues(Color.red, obj.width, obj.height)
          } else {
          obj.setValues(Yellow, obj.width, obj.height)
          }
        }

      }
    }
    clearEvents()
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
