import "input" for Keyboard
import "graphics" for Canvas, Color, Point
import "./util" for AABB
import "./renderables" for Rect, Sprite

import "./ecs/gamesystem" for GameSystem
import "./ecs/events" for Event, EventListener

import "./components" for
  ActiveComponent,
  PositionComponent,
  PhysicsComponent,
  PlayerControlComponent,
  TileComponent,
  ColliderComponent,
  EnemyAIComponent,
  RenderComponent

var Yellow = Color.rgb(255, 162, 00, 255)
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

      velocity.x = velocity.x + acceleration.x
      velocity.y = velocity.y + acceleration.y

      position.x = position.x + velocity.x
      position.y = position.y + velocity.y

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
    for (event in events) {
      // System.print("%(event.e1) -> %(event.e2)")
    }
  }
}

class DetectionEvent is Event {
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
    super(world, [PositionComponent, EnemyAIComponent])
    world.bus.subscribe(this, CollisionEvent)
  }

  update() {
    var player = world.getEntityByTag("player")

    for (entity in entities) {
      var collided = false
      for (event in events) {
        if ((event.e1 == player.id && event.e2 == entity.id) || (event.e1 == entity.id && event.e2 == player.id)) {
          collided = true
        }
      }
      var position = entity.getComponent(PositionComponent)
      var physics = entity.getComponent(PhysicsComponent)
      var ai = entity.getComponent(EnemyAIComponent)
      if (!collided) {
        physics.acceleration.x = 0
        physics.acceleration.y = 0
        physics.velocity.x = 0
        physics.velocity.y = 0
        var velocity = physics.velocity

        if (ai.mode == "horizontal") {
          velocity.x = ai.dir
          if ((ai.dir > 0 && position.x >= Canvas.width-16) || (ai.dir < 1 && position.x <= 0)) {
            ai.mode = "vertical"
          }
        } else if (ai.mode == "vertical") {
          velocity.y = 1
          ai.t = ai.t + 1
          if (ai.t >= 32) {
            ai.mode = "horizontal"
            ai.dir = -ai.dir
            ai.t = 0
          }
          if (position.y >= Canvas.height - 16) {
            ai.dir = -ai.dir
            ai.t = 0
            ai.mode = "reverse"
          }
        } else if (ai.mode == "reverse") {
          velocity.y = -1
          if (position.y <= 0) {
            ai.mode = "horizontal"
          }
        }
      } else {
          // get player entity
          var playerPosition = player.getComponent(PositionComponent).point

          var x = (position.x+8) - (playerPosition.x + 8)
          if (x < 0) {
            x = -1
            ai.t = 0
          } else if (x > 0) {
            x = 1
            ai.t = 0
          } else {
            x = 0
            ai.t = ai.t + 1
            if (ai.t > 60) {
              world.bus.publish(DetectionEvent.new())

            }
          }
          physics.velocity.x = -x / 2
      }
      if (collided) {
    entity.getComponent(RenderComponent).renderable.children[0].state = "active"
      } else {
    entity.getComponent(RenderComponent).renderable.children[0].state = "normal"
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
      var sprite = entity.getComponent(RenderComponent).renderable
      var x = 0
      var y = 0

      var stand = 0
      sprite.state = "standing"

      if (Keyboard.isKeyDown("left")) {
        x = x - 1
        stand = 48
        sprite.state = "running-left"
      }
      if (Keyboard.isKeyDown("right")) {
        x = x + 1
        stand = 16
        sprite.state = "running-right"
      }
      if (Keyboard.isKeyDown("up")) {
        y = y - 1
        stand = 32
        sprite.state = "running-up"
      }
      if (Keyboard.isKeyDown("down")) {
        y = y + 1
        stand = 0
        sprite.state = "running-down"
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
    super(world, [PositionComponent, RenderComponent, ActiveComponent])
  }
  update() {
    Canvas.cls(Color.black)
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
      var position = entity.getComponent(PositionComponent).point
      var renderable = entity.getComponent(RenderComponent).renderable

      if (renderable) {
        renderable.render(position + Point.new(-40*8, -60*8))
      }
    }
  }
}


class ColliderRenderSystem is GameSystem {
  construct init(world) {
    super(world, [ActiveComponent, PositionComponent, ColliderComponent])
  }

  update() {
    for (entity in entities) {
      var position = entity.getComponent(PositionComponent).point
      var collider = entity.getComponent(ColliderComponent).box

      var start = position + collider.pos

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
