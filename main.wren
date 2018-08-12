import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random
import "io" for FileSystem

import "./toml" for Toml

import "./gameover" for GameOverState
import "./util" for Box

import "./ecs/entity" for Entity
import "./ecs/component" for Component
import "./ecs/gamesystem" for GameSystem
import "./ecs/world" for World


// -------------------------
// ------- GAME CODE -------
// -------------------------
class Game {
  static init() {
    __state = MainGame
    __state.init()
    
    Toml.run("[word.word]\ntest = '''hel\nll\\no'''\n")
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
    __world = World.new()
    __world.addSystem(ScrollSystem)
    __world.addRenderSystem(RenderSystem)
    __world.addComponentManager(PositionComponent)
    __world.addComponentManager(RectComponent)

    __ship = __world.newEntity()
    __ship.addComponents([PositionComponent, RectComponent])
    __ship.setComponent(RectComponent.new(__ship.id, Color.white, 16, 32))
  }

  static update() {
    __t = __t + 1
    var x = 0
    var y = 0

    if (Keyboard.isKeyDown("left")) {
      x = -1
    }
    if (Keyboard.isKeyDown("right")) {
      x = 1
    }
    if (Keyboard.isKeyDown("up")) {
      y = -1
    }
    if (Keyboard.isKeyDown("down")) {
      y = 1
    }
    if (Keyboard.isKeyDown("space")) {
    }

    __world.update()
  }

  static draw(dt) {
    __world.render()
  }
}

