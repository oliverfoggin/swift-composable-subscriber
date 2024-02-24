import ComposableArchitecture

extension Reducer {
  
  public func onReceive<V>(
    action toReceiveAction: CaseKeyPath<Action, V>,
    set setAction: @escaping (inout State, V) -> Void
  ) -> _ReceiveReducer<Self, V> {
    .init(
      parent: self,
      receiveAction: AnyCasePath(toReceiveAction),
      setAction: setAction
    )
  }
  
  public func onReceive<V>(
    action toReceiveAction: CaseKeyPath<Action, V>,
    set toStateKeyPath: WritableKeyPath<State, V>
  ) -> _ReceiveReducer<Self, V> {
    self.onReceive(action: toReceiveAction, set: toStateKeyPath.callAsFunction(root:value:))
  }
  
  public func onReceive<V>(
    action toReceiveAction: CaseKeyPath<Action, V>,
    set toStateKeyPath: WritableKeyPath<State, V?>
  ) -> _ReceiveReducer<Self, V> {
    self.onReceive(action: toReceiveAction, set: toStateKeyPath.callAsFunction(root:value:))
  }
  
  public func onReceive<V>(
    action toReceiveAction: CaseKeyPath<Action, TaskResult<V>>,
    onSuccess setAction: @escaping (inout State, V) -> Void,
    onFail: OnFailAction<State>? = nil
  ) -> _ReceiveReducer<Self, TaskResult<V>> {
    self.onReceive(action: toReceiveAction) { state, result in
      switch result {
      case let .failure(error):
        if let onFail {
          onFail(state: &state, error: error)
        }
      case let .success(value):
        setAction(&state, value)
      }
    }
  }
  
  public func onReceive<V>(
    action toReceiveAction: CaseKeyPath<Action, TaskResult<V>>,
    onSuccess toStateKeyPath: WritableKeyPath<State, V>,
    onFail: OnFailAction<State>? = nil
  ) -> _ReceiveReducer<Self, TaskResult<V>> {
    self.onReceive(action: toReceiveAction) { state, result in
      switch result {
      case let .failure(error):
        if let onFail {
          onFail(state: &state, error: error)
        }
      case let .success(value):
        toStateKeyPath(root: &state, value: value)
      }
    }
  }
  
  public func onReceive<V>(
    action toReceiveAction: CaseKeyPath<Action, TaskResult<V>>,
    onSuccess toStateKeyPath: WritableKeyPath<State, V?>,
    onFail: OnFailAction<State>? = nil
  ) -> _ReceiveReducer<Self, TaskResult<V>> {
    self.onReceive(action: toReceiveAction) { state, result in
      switch result {
      case let .failure(error):
        if let onFail {
          onFail(state: &state, error: error)
        }
      case let .success(value):
        toStateKeyPath(root: &state, value: value)
      }
    }
  }
}

public enum OnFailAction<State> {
  case xctFail
  case handle((inout State, Error) -> Void)
  
  @usableFromInline
  func callAsFunction(state: inout State, error: Error) {
    switch self {
    case .xctFail:
      XCTFail("\(error)")
    case let .handle(handler):
      handler(&state, error)
    }
  }
}

fileprivate extension WritableKeyPath {
  
  func callAsFunction(root: inout Root, value: Value) {
    root[keyPath: self] = value
  }
  
}

public struct _ReceiveReducer<Parent: Reducer, Value>: Reducer {
  
  @usableFromInline
  let parent: Parent
  
  @usableFromInline
  let receiveAction: AnyCasePath<Parent.Action, Value>
  
  @usableFromInline
  let setAction: (inout Parent.State, Value) -> Void
    
  public func reduce(into state: inout Parent.State, action: Parent.Action) -> Effect<Parent.Action> {
    let baseEffects = parent.reduce(into: &state, action: action)
    
    if let value = receiveAction.extract(from: action) {
      setAction(&state, value)
    }
    
    return baseEffects
  }
}
