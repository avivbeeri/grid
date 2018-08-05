import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random
import "io" for FileSystem

import "./gameover" for GameOverState
import "./util" for Box


// -------------------------
// ------- GAME CODE -------
// -------------------------

class Game {
  static init() {
    __state = MainGame
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

class Entity {
  construct new() {
    if (__id == null) {
      __id = 0
    }
    _id = __id
    __id = __id + 1
  }  

  id { _id }
}

class MainGame {
  static next { __next}

  static init() {
    __next = null
    __t = 0
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
  }

  static draw(dt) {
    Canvas.cls()
  }
}

