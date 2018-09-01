class Event {}

class EventListener {
  events {
    if (_events == null) {
      _events = []
    }
    return _events
  }
  receive(event) {
    if (_events == null) {
      _events = []
    }
    _events.add(event)
  }
  clearEvents() {
    _events = []
  }
}

class EventBus {
  construct new() {
    _listenerMap = {}
    clear()
  }

  clear() {
    _events = []
  }

  publish(event) {
    if (event is Event && _listenerMap.containsKey(event.type)) {
      for (listener in _listenerMap[event.type]) {
        listener.receive(event)
      }
    }
  }

  subscribe(listener, eventType) {
    if (!(listener is EventListener)) {
      Fiber.abort("Tried to register something which is an EventListener")
    }
    if (!_listenerMap.containsKey(eventType)) {
      _listenerMap[eventType] = []
    }
    _listenerMap[eventType].add(listener)
  }

}
