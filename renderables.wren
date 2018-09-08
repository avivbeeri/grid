import "graphics" for Canvas, Color

class Renderable {
  render(position) {}
  children { [] }
}


class Sprite is Renderable {
  construct new(sprite) {
    _image = sprite
    setSrc(0, 0, _image.width, _image.height)
  }

  construct new(sprite, size) {
    _image = sprite
    setSrc(0, 0, size.x, size.y)
  }

  render(position) {
    _image.drawArea(_x, _y, _w, _h, position.x, position.y)
  }

  setSrc(x, y, w, h) {
    _x = x
    _y = y
    _w = w
    _h = h
  }

  x=(v) { _x = v }
  x { _x }

  image { _image }
}

class Rect is Renderable {
  construct new() {
    setValues(Color.white, 5, 5)
  }

  construct new(color) {
    setValues(color, 5, 5)
  }

  construct new(color, w, h) {
    setValues(color, w, h)
  }

  setValues(color, w, h) {
    _color = color
    _width = w
    _height = h
  }

  render(position) {
    Canvas.rectfill(position.x, position.y, width, height, color)
  }

  color { _color }
  width { _width }
  height { _height }
}

class Animation is Sprite {
  construct new(spritesheet, size, speed) {
    super(spritesheet)
    _size = size
    setSrc(0, 0, size.x, size.y)
    _t = 0
    _frameLength = speed
  }

  render(position) {
    super.render(position)
    _t = _t + 1
    if (_t > _frameLength) {
      x = (x + _size.x) % image.width
      _t = 0
    }
  }
}

class SpriteGroup is Renderable {
  construct new(state, spriteMap) {
    _state = state
    _map = spriteMap
  }

  state=(v) { _state = v }

  render(position) {
    _map[_state].render(position)
  }
}
