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
  ColliderResolutionSystem,
  RenderSystem,
  DetectionEvent

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


class TileMap {
  construct load(imageFileName, tileMapFileName, collisionMapFileName) {
    __tileMapWidth = (Canvas.width / 8) * 3
    __tileMapHeight = (Canvas.height / 8) * 3
    _image = ImageData.loadFromFile(imageFileName)
    _tileMapFile = FileSystem.loadSync(tileMapFileName)
    _collisionMapFile = FileSystem.loadSync(collisionMapFileName)
    _tileMap = _tileMapFile.replace(" ", "").replace("\n", ",").split(",").map {|n| Num.fromString(n) }.toList
    _collisionMap = _collisionMapFile.replace(" ", "").replace("\n", ",").split(",").map {|n| n != "-1" }.toList
  }

  getTileSprite(x, y) {
    var sprite = Sprite.new(_image, Point.new(8, 8))
    var tileValue = getTileAt(x, y)
    sprite.x = (tileValue % 8) * 8
    sprite.y = (tileValue / 8).floor * 8
    return sprite
  }

  getTileAt(x, y) {
    return _tileMap[y * __tileMapWidth + x]
  }

  isSolidAt(x, y) {
    return _collisionMap[y * __tileMapWidth + x]
  }

  static width { __tileMapWidth }
  static height { __tileMapHeight }

}

// -------------------------
// ------- GAME CODE -------
// -------------------------
class Game {
  static gameData { __gameData }
  static init() {

     var text = "[[entities]] \n"
     //text = text + "basic2.broken = \"Hello \nworld\" \n"
     // text = text + "test.broken = 'hello"
     text = text + "position.x = 472 \n"
     text = text + "position.y = 670 \n"

    var document = Toml.run(text)
    __gameData = TomlMapBuilder.new(document).build()
    System.print(__gameData)
    // __state = MainGame.init()
    __state = MainGame.init(TileMap.load("res/tiles.png", "res/level1_tiles.csv", "res/level1_collision.csv"))

    // __state.init()

  }
  static update() {

    if (__state) {
      __state.update()
      if (__state.next) {
        __state = __state.next.init()
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
    _world.addSystem(ColliderResolutionSystem)
    _world.addSystem(ScrollSystem)
    _world.addSystem(TestEventSystem)
    _world.addRenderSystem(RenderSystem)
    _world.bus.subscribe(this, DetectionEvent)
    _world.addRenderSystem(ColliderRenderSystem)

    // Create player
    _player = _world.newEntity()
    _world.setEntityTag("player", _player)

    _player.addComponents([ActiveComponent, PositionComponent, RenderComponent, PlayerControlComponent, PhysicsComponent, ColliderComponent])
    _player.getComponent(PositionComponent).x = Game.gameData["entities"][0]["position"]["x"]
    _player.getComponent(PositionComponent).y = Game.gameData["entities"][0]["position"]["y"]
    _player.setComponent(RenderComponent.new(_player.id, SpriteMap.new("standing", {
      "standing": Sprite.new(_ghostStanding, Point.new(16,32)),
      "running-left": Animation.new(_ghostRunningLeft, Point.new(16,32), 5),
      "running-right": Animation.new(_ghostRunningRight, Point.new(16,32), 5),
      "running-up": Animation.new(_ghostRunningUp, Point.new(16,32), 5),
      "running-down": Animation.new(_ghostRunningDown, Point.new(16,32), 5)
    })))
    _player.getComponent(ColliderComponent).box = AABB.new(0, 0, 16, 16)
    _player.getComponent(RenderComponent).renderable.offset = Point.new(0, -16)


    // Create tilemap
    var tileSize = 8
    var tileWidth = TileMap.width
    var tileHeight = TileMap.height
    for (y in 0...tileHeight) {
      for (x in 0...tileWidth) {
        // var tileData = tileMap[y * tileWidth + x]
        if (tileMap.getTileAt(x, y) > -1) {
          var tile = _world.newEntity()
          tile.addComponents([PositionComponent, RenderComponent, TileComponent])
          tile.setComponent(RenderComponent.new(tile.id, tileMap.getTileSprite(x, y), -2))

          if (tileMap.isSolidAt(x, y)) {
            tile.addComponents([ColliderComponent])
            tile.getComponent(ColliderComponent).box = AABB.new(0, 0, 8, 8)
          }
          tile.getComponent(PositionComponent).x = x * tileSize
          tile.getComponent(PositionComponent).y = y * tileSize
          if (x >= 40 && x < 80 && y >= 30 && y < 90) {
            tile.addComponents([ActiveComponent])
          }
        }
      }
    }

    // Enemy
    var enemyData = [
      // [x, y, mode, dist, speed]
      [42 * tileSize, 63 * tileSize, "vertical", 10, 0.5, 0, 1],
      [77 * tileSize, 68 * tileSize, "vertical", 10, 0.5, 5, -1]
    ]

    for (data in enemyData) {
      // Prefab
      _enemy = _world.newEntity()
      _enemy.addComponents([PositionComponent, RenderComponent, EnemyAIComponent, ColliderComponent, PhysicsComponent, ActiveComponent])
      _enemy.getComponent(ColliderComponent).box = AABB.new(-4, 47, tileSize*3+1, 12)
      _enemy.getComponent(ColliderComponent).type = ColliderComponent.Trigger
      _enemy.setComponent(RenderComponent.new(_enemy.id, SpriteGroup.new([SpriteMap.new("normal", {
        "normal": Animation.new(_droneSprite, Point.new(16,16), 1),
        "active": Animation.new(_droneActiveSprite, Point.new(16,16), 1),
      }), Ellipse.new(Color.new(95,87,79, 255), 24, 10)]), -1))
      _enemy.getComponent(RenderComponent).renderable.offset = Point.new(0, 0)
      _enemy.getComponent(RenderComponent).renderable.children[1].offset = Point.new(-4, 47)

      // Customise
      _enemy.getComponent(PositionComponent).x = data[0]
      _enemy.getComponent(PositionComponent).y = data[1]
      var ai = _enemy.getComponent(EnemyAIComponent)
      ai.mode = data[2]
      ai.dist = data[3]
      ai.speed = data[4]
      ai.t = (data[5] / ai.speed) * tileSize
      ai.dir = data[6]
    }

    // Truck
    var screenX = 1
    var screenY = 2
    _truck = _world.newEntity()
    _truck.addComponents([PositionComponent, RenderComponent, ColliderComponent, PhysicsComponent, ActiveComponent])
    _truck.getComponent(PositionComponent).x = tileSize * screenX * 40 + tileSize*20
    _truck.getComponent(PositionComponent).y = tileSize * screenY * 30 + tileSize*10
    _truck.getComponent(ColliderComponent).box = AABB.new(8, 0, 72, 40)
    _truck.getComponent(ColliderComponent).type = ColliderComponent.Solid

    _standingTruckSprite = ImageData.loadFromFile("res/truck-still.png")
    _drivingTruckSprite = ImageData.loadFromFile("res/truck-driving.png")

    _truck.setComponent(RenderComponent.new(_truck.id, SpriteMap.new("driving", {
      "standing": Sprite.new(_standingTruckSprite, Point.new(80,40)),
      "standing-on": Sprite.new(_standingTruckSprite, Point.new(80,40)),
      "driving": Animation.new(_drivingTruckSprite, Point.new(80,40), 2),
    }), -1))

    _truck.getComponent(RenderComponent).renderable["standing-on"].setSrc(80, 0, 80, 40)
  }

  update() {
    _t = _t + 1
    _world.update()
    for (event in events) {
      System.print(event)
      if (event is DetectionEvent) {
        _next = GameOverState
      }
    }
    clearEvents()

  }

  draw(dt) {
    _world.render()
  }
}

