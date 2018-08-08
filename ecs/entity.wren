class Entity {
  construct new(world, id) {
    _world = world
    _id = id
  }  

  id { _id }

  // Helper methods
  // Rather than calling the World object with unexpressive API
  

  addComponents(componentTypes) {
    return _world.addComponentsToEntity(this, componentTypes)
  }

  getComponent(componentType) {
    return _world.getComponentFromEntity(this, componentType)
  }

  hasComponent(componentType) {
    return _world.entityHasComponent(this, componentType)
  }
}
