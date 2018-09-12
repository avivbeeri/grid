import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random
import "io" for FileSystem

import "./ecs/events" for EventListener
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

     var text = "[[entities]] \n"
     //text = text + "basic2.broken = \"Hello \nworld\" \n"
     // text = text + "test.broken = 'hello"
     text = text + "position.x = 90 \n"
     text = text + "position.y = 160 \n"

    var document = Toml.run(text)
    __gameData = TomlMapBuilder.new(document).build()
    System.print(__gameData)
    // __state = MainGame.init()
    __tileMapFile = FileSystem.load("res/test.csv")

    // __state.init()

  }
  static update() {
    if (__tileMapFile.complete && !__done) {
      __done = true
      __tileMap = __tileMapFile.result.data.replace(" ", "").replace("\n", ",").split(",")
      __state = MainGame.init(__tileMap)
    }

    if (__state) {
      __state.update()
      if (__state.next) {
        __state = __state.next
        __state.init()
      }
    }
  }
  static draw(dt) {
    if (__state) {
      __state.draw(dt)
    }
  }
}



class MainGame is EventListener {
  next { _next}

  construct init(tileMap) {
    _next = null
    _t = 0
    _tileSet = ImageData.loadFromFile("res/tiles.png")
    _ghostStanding = ImageData.loadFromFile("res/ghost-standing.png")
    _ghostRunningDown = ImageData.loadFromFile("res/ghost-running-down.png")
    _ghostRunningUp = ImageData.loadFromFile("res/ghost-running-up.png")
    _ghostRunningLeft = ImageData.loadFromFile("res/ghost-running-left.png")
    _ghostRunningRight = ImageData.loadFromFile("res/ghost-running-right.png")
    _droneSprite = ImageData.loadFromFile("res/drone.png")
    _droneActiveSprite = ImageData.loadFromFile("res/drone-active.png")

    AudioEngine.load("music1", "res/nothalf.ogg")
    AudioEngine.load("music2", "res/around-the-corner.ogg")
    AudioEngine.play("music2", 1, true)

    // World system setup
    _world = World.new()
    _world.addSystem(PlayerControlSystem)
    _world.addSystem(EnemyAISystem)
    _world.addSystem(PhysicsSystem)
    _world.addSystem(CollisionSystem)
    _world.addSystem(TestEventSystem)
    _world.addRenderSystem(RenderSystem)
    _world.bus.subscribe(this, "detected")
    // _world.addRenderSystem(ColliderRenderSystem)

    // Create player
    _player = _world.newEntity()
    _world.setEntityTag("player", _player)

    _player.addComponents([PositionComponent, RenderComponent, PlayerControlComponent, PhysicsComponent, ColliderComponent])
    _player.getComponent(PositionComponent).x = Game.gameData["entities"][0]["position"]["x"]
    _player.getComponent(PositionComponent).y = Game.gameData["entities"][0]["position"]["y"]
    _player.setComponent(RenderComponent.new(_player.id, SpriteMap.new("standing", {
      "standing": Sprite.new(_ghostStanding, Point.new(16,32)),
      "running-left": Animation.new(_ghostRunningLeft, Point.new(16,32), 5),
      "running-right": Animation.new(_ghostRunningRight, Point.new(16,32), 5),
      "running-up": Animation.new(_ghostRunningUp, Point.new(16,32), 5),
      "running-down": Animation.new(_ghostRunningDown, Point.new(16,32), 5)
    })))
    _player.getComponent(ColliderComponent).box = AABB.new(0, 16, 16, 16)
    // _player.getComponent(RenderComponent).renderables[0]


    // Create tilemap
    var tileSize = 8
    var tileWidth = Canvas.width / tileSize
    var tileHeight = Canvas.height / tileSize
    for (y in 0...tileHeight) {
      for (x in 0...tileWidth) {
        var tileData = tileMap[y * tileWidth + x]
        var tile = _world.newEntity()
        tile.addComponents([PositionComponent, RenderComponent, TileComponent])
        tile.setComponent(RenderComponent.new(tile.id, Sprite.new(_tileSet, Point.new(8, 8)), -2))
        tile.getComponent(PositionComponent).x = x * tileSize
        tile.getComponent(PositionComponent).y = y * tileSize
        tile.getComponent(RenderComponent).renderable.x = (Num.fromString(tileData) % 8) * 8
        tile.getComponent(RenderComponent).renderable.y = (Num.fromString(tileData) / 8).floor * 8
      }
    }

    // Enemy
    _enemy = _world.newEntity()
    _enemy.addComponents([PositionComponent, RenderComponent,/* EnemyAIComponent,*/ ColliderComponent, PhysicsComponent])
    _enemy.getComponent(PositionComponent).x = 90
    _enemy.getComponent(PositionComponent).y = 20
    _enemy.getComponent(ColliderComponent).box = AABB.new(-4, 47, tileSize*3+1, 12)
    _enemy.setComponent(RenderComponent.new(_enemy.id, SpriteGroup.new([SpriteMap.new("normal", {
      "normal": Animation.new(_droneSprite, Point.new(16,16), 1),
      "active": Animation.new(_droneActiveSprite, Point.new(16,16), 1),
    }), Ellipse.new(Color.darkgray, 24, 10)]), -1))
    _enemy.getComponent(RenderComponent).renderable.offset = Point.new(0, 0)
    _enemy.getComponent(RenderComponent).renderable.children[1].offset = Point.new(-4, 47)
  }

  update() {
    _t = _t + 1
    _world.update()
    for (event in events) {
      System.print(event)
    }
    clearEvents()

  }

  draw(dt) {
    _world.render()
  }
}

