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
  construct new(id) {
    _id = id
    _componentSet = {}
  }  

  id { _id }
  hasComponent(componentType) {
    return _componentSet.containsKey(componentType)
  }
}

class EntityManager {
  static reset() {
    __nextId = 0
    __entities = []
  }
   
  static new() {
    var entity = Entity.new(__nextId) 
    __entities.insert(__nextId, entity)
    __nextId = __nextId + 1
    
    return entity
  }  
}

class Component {
  construct new(id) {
    _id = id
  }
  id { _id }
}

class PositionComponent is Component {}


class ComponentManager {
  construct init(ComponentClass) {
    if (!(ComponentClass is Component)) {
      Fiber.abort("Tried to initialise a componentManager but without a component")
    }  
    _ComponentClass = ComponentClass  
    _components = {}
  }

  components { _components } 
  addToEntity(entity) {
    _components[entity.id] = ComponentClass.new(entity.id)  
  }
}


class MainGame {
  static next { __next}

  static init() {
    __next = null
    __t = 0
    EntityManager.reset()
    
    __shipEntity = EntityManager.new()
    System.print(__shipEntity.id)
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

