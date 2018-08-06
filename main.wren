import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random
import "io" for FileSystem

import "./gameover" for GameOverState
import "./util" for Box

import "./entity" for Entity


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


class World {
  construct new() {
    _manager = EntityManager.init()
    _systems = []
    _renderSystems = []
    _componentManagers = {}
  }
  entities { _manager.entities }

  newEntity() {
    return _manager.new()
  }

  addSystem(systemType) {
    _systems.add(systemType.init(this))
  }

  addRenderSystem(systemType) {
    _renderSystems.add(systemType.init(this))
  }

  addComponentManager(componentType) {
    _componentManagers[componentType] = ComponentManager.new(componentType)
  }

  addComponentsToEntity(entity, componentTypes) {
    if (entity is Entity) {
      for (componentType in componentTypes) {
        _componentManagers[componentType].add(entity)
      }
    } 
  }

  entityHasComponent(entity, componentType) {
    return _componentManagers[componentType].has(entity)
  }

  getComponentFromEntity(entity, componentType) {
    return _componentManagers[componentType][entity]
  }

  update() {
    for (system in _systems) {
      system.update()
    }
  }
  render() {
    for (system in _renderSystems) {
      system.update()
    }
  }
}

class EntityManager {
  construct init() {
    _nextId = 1
    _entities = []
  }
   
  new() {
    var entity = Entity.new(_nextId) 
    _entities.add(entity)
    _nextId = _nextId + 1
    
    return entity
  }  

  entities { _entities }
}

class Component {
  construct new(id) {
    _id = id
  }
  id { _id }
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


class ComponentManager {
  construct new(ComponentClass) {
    _ComponentClass = ComponentClass  
    _components = {}
  }

  components { _components } 
  add(entity) {
    if (entity is Entity && entity.id is Num) {
      _components[entity.id] = _ComponentClass.new(entity.id)  
    }
  }

  has(entity) {
    return _components.containsKey(entity.id)
  }

  remove(entity) {
    return _components.remove(entity.id)
  }
  [index] {
    if (index is Num) {
      return _components[index]
    } else if (index is Entity) {
      return _components[index.id]
    }
  }

  iterate(i) {
    return _components.keys.iterate(i)  
  }

  iteratorValue(key) {
    return _components[_components.keys.iteratorValue(key)]
  }
}

class GameSystem {
  construct init(world, requires) { 
    _world = world 
    _requires = requires
  }
  world { _world }
  update() {}
  entities {
    // TODO: Redo this function
    var allowedEntities = []
    for (entity in world.entities) {
      var resultSize = 0
      for (type in _requires) {
        if (world.entityHasComponent(entity, type)) {
          resultSize = resultSize + 1
        }
      }
      if (resultSize == _requires.count) {
        allowedEntities.add(entity)
      } 
    }
    return allowedEntities
  }
}

class ScrollSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent])
  }
  update() {
    for (entity in entities) {
      var position = world.getComponentFromEntity(entity, PositionComponent)
      position.x = (position.x + 1) % Canvas.width
     
    }
  }
}

class RectComponent is Component {
  construct new(id) { 
    super(id) 
  }
}

class RenderSystem is GameSystem {
  construct init(world) {
    super(world, [PositionComponent, RectComponent])
  }
  update() {
    Canvas.cls()
    for (entity in entities) {
      var position = world.getComponentFromEntity(entity, PositionComponent)
      Canvas.rectfill(position.x, position.y, 5, 5, Color.white)
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
    __world.addComponentsToEntity(__ship, [PositionComponent, RectComponent])
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

