import "./ecs/component" for Component

// Behaves like the EntityHandle in the Nomad engine
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

  setComponent(component) {
    return _world.setComponentOfEntity(this, component)
  }

  removeComponent(component) {
    return _world.removeComponentFromEntity(this, component)
  }
}
