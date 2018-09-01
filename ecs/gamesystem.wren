import "./ecs/component" for Component
import "./ecs/events" for EventListener
import "./util" for Utils

class GameSystem is EventListener {
  construct init(world, requires) {
    _world = world
    _requires = requires
    for (componentType in requires) {
      if (!Component.isComponentType(componentType)) {
        Fiber.abort("Requiring a non-component type %(componentType)")
      }
      world.addComponentManager(componentType)
    }
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
