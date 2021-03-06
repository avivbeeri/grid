import "./ecs/entity" for Entity
import "./ecs/component" for Component
import "./ecs/gamesystem" for GameSystem
import "./util" for Utils
import "./ecs/events" for EventBus

class World {
  construct new() {
    _manager = EntityManager.init(this)
    _systems = []
    _renderSystems = []
    _componentManagers = {}
    _eventBus = EventBus.new()
  }
  entities { _manager.entities }
  bus { _eventBus }

  newEntity() {
    clearSystemCaches()
    return _manager.new()
  }

  clearSystemCaches() {
    for (system in _systems) {
      system.clearEntityCache()
    }
    for (system in _renderSystems) {
      system.clearEntityCache()
    }
  }

  setEntityTag(tag, entity) {
    _manager.tag(tag, entity)
  }

  getEntityByTag(tag) {
    return _manager[tag]
  }
  getEntityById(id) {
    return _manager[id]
  }

  removeEntity(entity) {
    for (componentManager in _componentManagers) {
      componentManager.remove(entity)
    }
    _manager.remove(entity)
  }

  addSystem(systemType) {
    if (GameSystem.isSystemType(systemType)) {
      _systems.add(systemType.init(this))
    } else {
      Fiber.abort("Trying to add non-system %(systemType) to the world")
    }
  }

  addRenderSystem(systemType) {
    if (GameSystem.isSystemType(systemType)) {
      _renderSystems.add(systemType.init(this))
    } else {
      Fiber.abort("Trying to add non-system %(systemType) to the world")
    }
  }

  addComponentManager(componentType) {
    componentType = Component.getSubtype(componentType)
    if (!_componentManagers.containsKey(componentType)) {
      _componentManagers[componentType] = ComponentManager.new(componentType)
    }
  }

  addComponentsToEntity(entity, componentTypes) {
    if (entity is Entity) {
      for (componentType in componentTypes) {
        if (Component.isComponentType(componentType)) {
          addComponentToEntity(entity, componentType)
        }
      }
    }
  }

  addComponentToEntity(entity, componentType) {
    if (entity is Entity) {
      addComponentManager(componentType)
      _componentManagers[componentType].add(entity)
    }
  }

  entityHasComponent(entity, componentType) {
    // PRE: assumes a manager exists
    return _componentManagers[componentType].has(entity)
  }

  getComponentFromEntity(entity, componentType) {
    componentType = Component.getSubtype(componentType)
    // PRE: assumes a manager exists
    return _componentManagers[componentType][entity]
  }

  removeComponentFromEntity(entity, component) {
    // PRE: assumes a manager exists
    if (component is Class && Component.isComponentType(component)) {
      var componentType = Component.getSubtype(component)
      return _componentManagers[componentType].remove(entity)
    } else if (component is Component) {
      var componentType = Component.getSubtype(component.type)
      return _componentManagers[componentType].remove(entity)
    }
  }

  setComponentOfEntity(entity, component) {
    // PRE: assumes a manager exists
    addComponentManager(component.type)
    _componentManagers[component.type][entity] = component
  }

  update() {
    for (system in _systems) {
      system.update()
      system.clearEvents()
    }
  }

  render(dt) {
    for (system in _renderSystems) {
      system.update(dt)
    }
  }
}

class EntityManager {
  construct init(world) {
    _nextId = 1
    _entities = {}
    _tags = {}
    _world = world
  }

  new() {
    var entity = Entity.new(_world, _nextId)
    _entities[entity.id] = entity
    _nextId = _nextId + 1

    return entity
  }

  remove(entity) {
    return _entities.remove(entity.id)
  }

  tag(name, entity) {
    _tags[name] = entity.id
  }
  [index] {
    if (index is Num) {
      return _entities[index]
    } else if (index is String) {
      return _entities[_tags[index]]
    } else {
      Fiber.abort("Attempted to get entity with invalid index %(index)")
    }
  }

  entities { _entities.values.toList }
}

class ComponentManager {
  construct new(ComponentClass) {
    _ComponentClass = ComponentClass
    _components = {}
  }

  components { _components }
  add(entity) {
    if (entity is Entity) {
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

  [index]=(value) {
    if (value.type == _ComponentClass) {
      if (index is Num) {
        _components[index] = value
      } else if (index is Entity) {
        _components[index.id] = value
      }
    }
  }

  // Iterator protocol implementation
  iterate(i) {
    return _components.keys.iterate(i)
  }

  iteratorValue(key) {
    return _components[_components.keys.iteratorValue(key)]
  }
}
