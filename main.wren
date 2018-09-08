import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random

import "./ecs/world" for World
import "./util" for AABB

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
  RenderSystem

import "./components" for
  PositionComponent,
  PhysicsComponent,
  PlayerControlComponent,
  TileComponent,
  ColliderComponent,
  EnemyAIComponent,
  RenderComponent,
  Renderable,
  Rect,
  Sprite


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

    // World system setup
    __world = World.new()
    __world.addSystem(PlayerControlSystem)
    __world.addSystem(EnemyAISystem)
    __world.addSystem(PhysicsSystem)
    __world.addSystem(CollisionSystem)
    __world.addSystem(TestEventSystem)
    __world.addRenderSystem(RenderSystem)

    // Create player
    __player = __world.newEntity()
    __world.setEntityTag("player", __player)

    __player.addComponents([PositionComponent, RenderComponent, PlayerControlComponent, PhysicsComponent, ColliderComponent])
    __player.getComponent(PositionComponent).x = Game.gameData["entities"][0]["position"]["x"]
    __player.getComponent(PositionComponent).y = Game.gameData["entities"][0]["position"]["y"]
    __player.setComponent(RenderComponent.new(__player.id, [ Sprite.new(__ghostStanding) ]))
    __player.getComponent(ColliderComponent).box = AABB.new(0, 0, 16, 32)
    __player.getComponent(RenderComponent).renderables[0].setSrc(0,0,16,32)


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
    __enemy.addComponents([PositionComponent, RenderComponent, EnemyAIComponent, ColliderComponent, PhysicsComponent])
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
    // Canvas.ellipsefill( 20, 20, 70, 40, Color.green)
    // __ghostStanding.drawArea(48,0,16,32,0,0)
  }
}

