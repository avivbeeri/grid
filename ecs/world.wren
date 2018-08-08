import "./ecs/entity" for Entity
import "./ecs/component" for Component

class World {
  construct new() {
    _manager = EntityManager.init(this)
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
        addComponentToEntity(entity, componentType)
      }
    } 
  }

  addComponentToEntity(entity, componentType) {
    if (entity is Entity && _componentManagers.containsKey(componentType)) {
     System.print(componentType)
      _componentManagers[componentType].add(entity)
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
  construct init(world) {
    _nextId = 1
    _entities = []
    _world = world
  }
   
  new() {
    var entity = Entity.new(_world, _nextId) 
    _entities.add(entity)
    _nextId = _nextId + 1
    
    return entity
  }  

  entities { _entities }
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
