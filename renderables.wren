import "graphics" for Canvas, Color, Point

class Renderable {
  render(position) {}
  children { [] }
  offset { _offset || Point.new(0,0) }
  offset=(v) { _offset = v }
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
    var out = position + offset
    _image.drawArea(_x, _y, _w, _h, out.x, out.y)
  }

  setSrc(x, y, w, h) {
    _x = x
    _y = y
    _w = w
    _h = h
  }

  x=(v) { _x = v }
  y=(v) { _y = v }
  x { _x }
  y { _y }

  image { _image }
}

class Ellipse is Renderable {
  construct new(color, a, b) {
    _color = color
    _a = a
    _b = b
  }

  render(position) {
    var out = position + offset
    Canvas.ellipsefill(out.x, out.y, out.x+_a, out.y+_b, _color)
  }

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
    var out = position + offset
    Canvas.rectfill(out.x, out.y, width, height, color)
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
    var out = position + offset
    super.render(out)
    _t = _t + 1
    if (_t > _frameLength) {
      x = (x + _size.x) % image.width
      _t = 0
    }
  }
}

class SpriteGroup is Renderable {
  construct new(renderables) {
    _list = renderables[0..-1]
  }

  render(position) {
    for (r in _list) {
      r.render(position + offset)
    }
  }

  children { _list }
}

class SpriteMap is Renderable {
  construct new(state, spriteMap) {
    _state = state
    _map = spriteMap
  }

  state=(v) { _state = v }

  render(position) {
    _map[_state].render(position + offset)
  }
  [v] { _map[v] }
}
