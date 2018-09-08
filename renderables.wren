import "graphics" for Canvas, Color

class Renderable {
  render(position) {}
}

class Sprite is Renderable {
  construct new(sprite) {
    _image = sprite
    _x = 0
    _y = 0
    _w = _image.width
    _h = _image.height
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
