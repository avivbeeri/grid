import "input" for Keyboard
import "graphics" for Canvas, Color
import "./main" for MainGame

// State displays a "Game Over" message and allows a restart
class GameOverState {
  next { _next}
  construct init() {
    _next = null
    _hold = 0
  }
  update() {
    if (Keyboard.isKeyDown("space")) {
      _hold = _hold + 1
      if (_hold > 4) {
        _next = MainGame
      }
    } else {
      _hold = 0
    }
  }

  draw(dt) {
    Canvas.cls()
    Canvas.print("Game Over", 160-27, 120-3, Color.white)
  }
}
