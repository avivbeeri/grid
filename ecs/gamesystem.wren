import "./ecs/component" for Component
import "./util" for Utils

class GameSystem {
  construct init(world, requires) { 
    for (componentType in requires) {
      if (!Component.isComponentType(componentType)) {
        Fiber.abort("Requiring a non-component type %(componentType)") 
      }
    }
    _world = world 
    _requires = requires
  }
  world { _world }
  update() {}
  entities {
    var allowedEntities = []
    for (entity in world.entities) {
      var resultSize = 0
      for (type in _requires) {
        if (entity.hasComponent(type)) {
          resultSize = resultSize + 1
        }
      }
      if (resultSize == _requires.count) {
        allowedEntities.add(entity)
      } 
    }
    return allowedEntities
  }

  static isSystemType(classObject) {
    return Utils.isClassDescendant(classObject, GameSystem)
  }
}
