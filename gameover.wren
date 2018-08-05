import "input" for Keyboard
import "graphics" for Canvas, Color 
import "./main" for MainGame

// State displays a "Game Over" message and allows a restart
class GameOverState {
  static next { __next}
  static init() {
    __next = null
    __hold = 0
  }
  static update() {
    if (Keyboard.isKeyDown("space")) {
      __hold = __hold + 1
      if (__hold > 4) {
        __next = MainGame
      }
    } else {
      __hold = 0
    }
  }

  static draw(dt) {
    Canvas.cls()
    Canvas.print("Game Over", 160-27, 120-3, Color.white)
  }
}
