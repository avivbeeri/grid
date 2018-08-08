class GameSystem {
  construct init(world, requires) { 
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
}
