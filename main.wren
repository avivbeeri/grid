import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random

import "./ecs/world" for World
import "./util" for AABB
import "./renderables" for Rect, Sprite, Animation, SpriteMap, SpriteGroup, Ellipse

import "./toml/toml" for Toml
import "./toml/toml-map-builder" for TomlMapBuilder
import "./gameover" for GameOverState


import "./systems" for
  PhysicsSystem,
  TestEventSystem,
  CollisionSystem,
  EnemyAISystem,
  PlayerControlSystem,
  ScrollSystem,
  ColliderRenderSystem,
  RenderSystem

import "./components" for
  PositionComponent,
  PhysicsComponent,
  PlayerControlComponent,
  TileComponent,
  ColliderComponent,
  EnemyAIComponent,
  RenderComponent


var Yellow = Color.rgb(255, 162, 00, 255)

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



class MainGame {
  static next { __next}

  static init() {
    __next = null
    __t = 0
    __ghostStanding = ImageData.loadFromFile("res/ghost-standing.png")
    __ghostRunningDown = ImageData.loadFromFile("res/ghost-running-down.png")
    __ghostRunningUp = ImageData.loadFromFile("res/ghost-running-up.png")
    __ghostRunningLeft = ImageData.loadFromFile("res/ghost-running-left.png")
    __ghostRunningRight = ImageData.loadFromFile("res/ghost-running-right.png")
    __droneSprite = ImageData.loadFromFile("res/drone.png")
    __droneActiveSprite = ImageData.loadFromFile("res/drone-active.png")

    // World system setup
    __world = World.new()
    __world.addSystem(PlayerControlSystem)
    __world.addSystem(EnemyAISystem)
    __world.addSystem(PhysicsSystem)
    __world.addSystem(CollisionSystem)
    __world.addSystem(TestEventSystem)
    __world.addRenderSystem(RenderSystem)
    // __world.addRenderSystem(ColliderRenderSystem)

    // Create player
    __player = __world.newEntity()
    __world.setEntityTag("player", __player)

    __player.addComponents([PositionComponent, RenderComponent, PlayerControlComponent, PhysicsComponent, ColliderComponent])
    __player.getComponent(PositionComponent).x = Game.gameData["entities"][0]["position"]["x"]
    __player.getComponent(PositionComponent).y = Game.gameData["entities"][0]["position"]["y"]
    __player.setComponent(RenderComponent.new(__player.id, SpriteMap.new("standing", {
      "standing": Sprite.new(__ghostStanding, Point.new(16,32)),
      "running-left": Animation.new(__ghostRunningLeft, Point.new(16,32), 5),
      "running-right": Animation.new(__ghostRunningRight, Point.new(16,32), 5),
      "running-up": Animation.new(__ghostRunningUp, Point.new(16,32), 5),
      "running-down": Animation.new(__ghostRunningDown, Point.new(16,32), 5)
    })))
    __player.getComponent(ColliderComponent).box = AABB.new(0, 16, 16, 16)
    // __player.getComponent(RenderComponent).renderables[0]


    // Create tilemap
    var tileSize = 8
    for (y in 0...(Canvas.height/ tileSize)) {
      for (x in 0...(Canvas.width/ tileSize)) {
        var tile = __world.newEntity()
        tile.addComponents([PositionComponent, RenderComponent, TileComponent])
        tile.setComponent(RenderComponent.new(__player.id, Rect.new(Color.darkgray, tileSize, tileSize), -2))
        tile.getComponent(PositionComponent).x = x * tileSize
        tile.getComponent(PositionComponent).y = y * tileSize
      }
    }

    // Enemy
    __enemy = __world.newEntity()
    __enemy.addComponents([PositionComponent, RenderComponent, EnemyAIComponent, ColliderComponent, PhysicsComponent])
    __enemy.getComponent(PositionComponent).y = 20
    __enemy.getComponent(ColliderComponent).box = AABB.new(-4, 30, tileSize*3, tileSize*3)
    __enemy.setComponent(RenderComponent.new(__enemy.id, SpriteGroup.new([SpriteMap.new("normal", {
      "normal": Animation.new(__droneSprite, Point.new(16,16), 1),
      "active": Animation.new(__droneActiveSprite, Point.new(16,16), 1),
    }), Ellipse.new(Color.green, 24, 10)]), -1))
    __enemy.getComponent(RenderComponent).renderable.offset = Point.new(0, 0)
    __enemy.getComponent(RenderComponent).renderable.children[1].offset = Point.new(-4, 47)
  }

  static update() {
    __t = __t + 1
    __world.update()
  }

  static draw(dt) {
    __world.render()
  }
}

