import ComposableArchitecture
import SwiftUI

extension Reducer {
  /// A higher order reducer for subscribing to an `AsyncStream` from your app.
  ///
  /// A common pattern in our app for shared data is to create a dependency that exposes an `AsyncStream` of data that is shared.
  ///
  /// Then the `Reducer` on a `task` action we can do something like...
  /// ```swift
  /// Reduce<State, Action> { state, action in
  ///   switch action {
  ///    case.task:
  ///     return .run { send in
  ///       for await value in await dependency.stream() {
  ///         await send(.responseAction(value))
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  /// When you have a lot of publishers/subscribers this gets very repetetive.
  ///
  /// This gives a new way to subscribe to an async stream using a higher order reducer.
  ///
  /// Any dependency that returns an `AsyncStream` can be subscribed to in the following way.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   struct State: Equatable {
  ///     var numberFact: String?
  ///   }
  ///
  ///   enum Action {
  ///     case receiveNumberFact(String)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberFact.stream) var numberFactStream
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce<State, Action> { state, action in
  ///       switch action {
  ///      case let .receiveNumberFact(numberFact):
  ///         state.numberFact = numberFact
  ///         return .none
  ///      case .task:
  ///         return .none
  ///       }
  ///     }
  ///     .subscribe(to: numberFactStream, on: \.task, with: \.receive)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - stream: The async stream to subscribe to on the reducer
  ///   - triggerAction: The action to invoke the stream when received.
  ///   - responseAction: The action to invoke with the streamed elements.
  ///   - animation: Optional animation used when elements are received.
  public func subscribe<TriggerAction, StreamElement>(
		to stream: @escaping @Sendable () async -> AsyncStream<StreamElement>,
		on triggerAction: CaseKeyPath<Action, TriggerAction>,
		with responseAction: CaseKeyPath<Action, StreamElement>,
		animation: Animation? = nil
	) -> _SubscribeReducer<Self, TriggerAction, StreamElement, StreamElement> {
		.init(
			parent: self,
			on: triggerAction,
      to: .noState(stream: stream),
			with: .action(action: AnyCasePath(responseAction), animation: animation),
			transform: { $0 }
		)
	}
  
  /// A higher order reducer for subscribing to an `AsyncStream` from your app.
  ///
  /// A common pattern in our app for shared data is to create a dependency that exposes an `AsyncStream` of data that is shared.
  ///
  /// Then the `Reducer` on a `task` action we can do something like...
  /// ```swift
  /// Reduce<State, Action> { state, action in
  ///   switch action {
  ///    case.task:
  ///     return .run { send in
  ///       for await value in await dependency.stream() {
  ///         await send(.responseAction(value))
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  /// When you have a lot of publishers/subscribers this gets very repetitive.
  ///
  /// This gives a new way to subscribe to an async stream using a higher order reducer.
  ///
  /// Any dependency that returns an `AsyncStream` can be subscribed to in the following way.
  ///
  /// ## Example
  ///
  /// In this example, to invoke the stream we need a piece of information on the current `State` of the reducer.
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   struct State: Equatable {
  ///     var number: Int
  ///     var numberFact: String
  ///   }
  ///
  ///   enum Action {
  ///     case receiveNumberFact(String)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberFact.stream) var numberFactStream
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce<State, Action> { state, action in
  ///       switch action {
  ///      case let .receiveNumberFact(numberFact):
  ///         state.numberFact = numberFact
  ///         return .none
  ///      case .task:
  ///         return .none
  ///       }
  ///     }
  ///     .subscribe(using: \.number, to: numberFactStream, on: \.task, with: \.receive)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - stream: The async stream to subscribe to on the reducer
  ///   - toStreamArgument: The argument used to invoke the stream with.
  ///   - triggerAction: The action to invoke the stream when received.
  ///   - responseAction: The action to invoke with the streamed elements.
  ///   - animation: Optional animation used when elements are received.
  public func subscribe<TriggerAction, StreamElement, StreamArgument>(
    to stream: @escaping @Sendable (StreamArgument) async -> AsyncStream<StreamElement>,
    using toStreamArgument: @escaping @Sendable (State) -> StreamArgument,
    on triggerAction: CaseKeyPath<Action, TriggerAction>,
    with responseAction: CaseKeyPath<Action, StreamElement>,
    animation: Animation? = nil
  ) -> _SubscribeReducer<Self, TriggerAction, StreamElement, StreamElement> {
    .init(
      parent: self,
      on: triggerAction,
      to: .state(stream: { await stream(toStreamArgument($0)) }),
      with: .action(action: AnyCasePath(responseAction), animation: animation),
      transform: { $0 }
    )
  }
  
  /// A higher order reducer for subscribing to an `AsyncStream` from your app.
  ///
  /// A common pattern in our app for shared data is to create a dependency that exposes an `AsyncStream` of data that is shared.
  ///
  /// Then the `Reducer` on a `task` action we can do something like...
  /// ```swift
  /// Reduce<State, Action> { state, action in
  ///   switch action {
  ///    case.task:
  ///     return .run { send in
  ///       for await value in await dependency.stream() {
  ///         await send(.responseAction(value))
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  /// When you have a lot of publishers/subscribers this gets very repetetive.
  ///
  /// This gives a new way to subscribe to an async stream using a higher order reducer.
  ///
  /// Any dependency that returns an `AsyncStream` can be subscribed to in the following way.
  ///
  /// ## Example
  ///
  /// In this example, we transform the output of the stream that we subscribe to.
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   struct State: Equatable {
  ///     var numberFact: String?
  ///   }
  ///
  ///   enum Action {
  ///     case receiveNumberFact(String)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberFact.stream) var numberFactStream
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce<State, Action> { state, action in
  ///       switch action {
  ///      case let .receiveNumberFact(numberFact):
  ///         state.numberFact = numberFact
  ///         return .none
  ///      case .task:
  ///         return .none
  ///       }
  ///     }
  ///     .subscribe(to: numberFactStream, on: \.task, with: \.receive) { numberFact in
  ///       "\(numberFact) And my custom transformation"
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - stream: The async stream to subscribe to on the reducer
  ///   - triggerAction: The action to invoke the stream when received.
  ///   - responseAction: The action to invoke with the streamed elements.
  ///   - animation: Optional animation used when elements are received.
	public func subscribe<TriggerAction, StreamElement, Value>(
		to stream: @escaping @Sendable () async -> AsyncStream<StreamElement>,
		on triggerAction: CaseKeyPath<Action, TriggerAction>,
		with responseAction: CaseKeyPath<Action, Value>,
		animation: Animation? = nil,
		transform: @escaping @Sendable (StreamElement) -> Value
	) -> _SubscribeReducer<Self, TriggerAction, StreamElement, Value> {
		.init(
			parent: self,
			on: triggerAction,
      to: .noState(stream: stream),
			with: .action(action: AnyCasePath(responseAction), animation: animation),
			transform: transform
		)
	}
  
  /// A higher order reducer for subscribing to an `AsyncStream` from your app.
  ///
  /// A common pattern in our app for shared data is to create a dependency that exposes an `AsyncStream` of data that is shared.
  ///
  /// Then the `Reducer` on a `task` action we can do something like...
  /// ```swift
  /// Reduce<State, Action> { state, action in
  ///   switch action {
  ///    case.task:
  ///     return .run { send in
  ///       for await value in await dependency.stream() {
  ///         await send(.responseAction(value))
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  /// When you have a lot of publishers/subscribers this gets very repetitive.
  ///
  /// This gives a new way to subscribe to an async stream using a higher order reducer.
  ///
  /// Any dependency that returns an `AsyncStream` can be subscribed to in the following way.
  ///
  /// ## Example
  ///
  /// In this example, to invoke the stream we need a piece of information on the current `State` of the reducer.
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   struct State: Equatable {
  ///     var number: Int
  ///     var numberFact: String
  ///   }
  ///
  ///   enum Action {
  ///     case receiveNumberFact(String)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberFact.stream) var numberFactStream
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce<State, Action> { state, action in
  ///       switch action {
  ///      case let .receiveNumberFact(numberFact):
  ///         state.numberFact = numberFact
  ///         return .none
  ///      case .task:
  ///         return .none
  ///       }
  ///     }
  ///     .subscribe(using: \.number, to: numberFactStream, on: \.task, with: \.receive) { numberFact in
  ///       "\(numberFact) Appended with my custom transformation."
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - stream: The async stream to subscribe to on the reducer
  ///   - toStreamArgument: The argument used to invoke the stream with.
  ///   - triggerAction: The action to invoke the stream when received.
  ///   - responseAction: The action to invoke with the streamed elements.
  ///   - animation: Optional animation used when elements are received.
  public func subscribe<TriggerAction, StreamElement, Value, StreamArgument>(
    to stream: @escaping @Sendable (StreamArgument) async -> AsyncStream<StreamElement>,
    using toStreamArgument: @escaping @Sendable (State) -> StreamArgument,
    on triggerAction: CaseKeyPath<Action, TriggerAction>,
    with responseAction: CaseKeyPath<Action, Value>,
    animation: Animation? = nil,
    transform: @escaping @Sendable (StreamElement) -> Value
  ) -> _SubscribeReducer<Self, TriggerAction, StreamElement, Value> {
    .init(
      parent: self,
      on: triggerAction,
      to: .state(stream: { await stream(toStreamArgument($0)) }),
      with: .action(action: AnyCasePath(responseAction), animation: animation),
      transform: transform
    )
  }
  
  /// A higher order reducer for subscribing to an `AsyncStream` from your app.
  ///
  /// A common pattern in our app for shared data is to create a dependency that exposes an `AsyncStream` of data that is shared.
  ///
  /// Then the `Reducer` on a `task` action we can do something like...
  /// ```swift
  /// Reduce<State, Action> { state, action in
  ///   switch action {
  ///    case.task:
  ///     return .run { send in
  ///       for await value in await dependency.stream() {
  ///         await send(.responseAction(value))
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  /// When you have a lot of publishers/subscribers this gets very repetetive.
  ///
  /// This gives a new way to subscribe to an async stream using a higher order reducer.
  ///
  /// Any dependency that returns an `AsyncStream` can be subscribed to in the following way.
  ///
  /// ## Example
  ///
  /// In this example, we use the stream element to also call another operation on an external dependency.
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   struct State: Equatable {
  ///     var numberFact: String?
  ///   }
  ///
  ///   enum Action {
  ///     case receiveNumberFact(String)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberFact.stream) var numberFactStream
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce<State, Action> { state, action in
  ///       switch action {
  ///      case let .receiveNumberFact(numberFact):
  ///         state.numberFact = numberFact
  ///         return .none
  ///      case .task:
  ///         return .none
  ///       }
  ///     }
  ///     .subscribe(on: \.task, with: \.receive) { send, numberFact in
  ///       await send(.receive(numberFact))
  ///       await otherDependency.doSomethingElse(with: numberFact)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - stream: The async stream to subscribe to on the reducer
  ///   - triggerAction: The action to invoke the stream when received.
  ///   - responseAction: The action to invoke with the streamed elements.
  ///   - animation: Optional animation used when elements are received.
	public func subscribe<TriggerAction, StreamElement>(
		to stream: @escaping @Sendable () async -> AsyncStream<StreamElement>,
		on triggerAction: CaseKeyPath<Action, TriggerAction>,
		operation: @escaping @Sendable (_ send: Send<Action>, StreamElement) async throws -> Void
	) -> _SubscribeReducer<Self, TriggerAction, StreamElement, StreamElement> {
		.init(
			parent: self,
			on: triggerAction,
      to: .noState(stream: stream),
			with: .operation(f: operation),
			transform: { $0 }
		)
	}
  
  /// A higher order reducer for subscribing to an `AsyncStream` from your app.
  ///
  /// A common pattern in our app for shared data is to create a dependency that exposes an `AsyncStream` of data that is shared.
  ///
  /// Then the `Reducer` on a `task` action we can do something like...
  /// ```swift
  /// Reduce<State, Action> { state, action in
  ///   switch action {
  ///    case.task:
  ///     return .run { send in
  ///       for await value in await dependency.stream() {
  ///         await send(.responseAction(value))
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  /// When you have a lot of publishers/subscribers this gets very repetetive.
  ///
  /// This gives a new way to subscribe to an async stream using a higher order reducer.
  ///
  /// Any dependency that returns an `AsyncStream` can be subscribed to in the following way.
  ///
  /// ## Example
  ///
  /// In this example, we use the stream element to also call another operation on an external dependency.
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   struct State: Equatable {
  ///     var number: Int
  ///     var numberFact: String?
  ///   }
  ///
  ///   enum Action {
  ///     case receiveNumberFact(String)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberFact.stream) var numberFactStream
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce<State, Action> { state, action in
  ///       switch action {
  ///      case let .receiveNumberFact(numberFact):
  ///         state.numberFact = numberFact
  ///         return .none
  ///      case .task:
  ///         return .none
  ///       }
  ///     }
  ///     .subscribe(using: \.number, on: \.task, with: \.receive) { send, numberFact in
  ///       await send(.receive(numberFact))
  ///       await otherDependency.doSomethingElse(with: numberFact)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - stream: The async stream to subscribe to on the reducer
  ///   - toStreamArgument: The argument used to invoke the stream with.
  ///   - triggerAction: The action to invoke the stream when received.
  ///   - responseAction: The action to invoke with the streamed elements.
  ///   - animation: Optional animation used when elements are received.
  public func subscribe<TriggerAction, StreamElement, StreamArgument>(
    to stream: @escaping @Sendable (StreamArgument) async -> AsyncStream<StreamElement>,
    using toStreamArgument: @escaping @Sendable (State) -> StreamArgument,
    on triggerAction: CaseKeyPath<Action, TriggerAction>,
    operation: @escaping @Sendable (_ send: Send<Action>, StreamElement) async throws -> Void
  ) -> _SubscribeReducer<Self, TriggerAction, StreamElement, StreamElement> {
    .init(
      parent: self,
      on: triggerAction,
      to: .state(stream: { await stream(toStreamArgument($0)) }),
      with: .operation(f: operation),
      transform: { $0 }
    )
  }
}

@usableFromInline
enum Operation<Action, Value> {
	case action(action: AnyCasePath<Action, Value>, animation: Animation?)
	case operation(f: (_ send: Send<Action>, Value) async throws -> Void)
}

@usableFromInline
enum Stream<State, Value> {
  case noState(stream: (@Sendable () async -> AsyncStream<Value>))
  case state(stream: (@Sendable (State) async -> AsyncStream<Value>))
  
  fileprivate func callAsFunction(state: State) async -> AsyncStream<Value> {
    switch self {
    case let .noState(stream: stream):
      return await stream()
    case let .state(stream: stream):
      return await stream(state)
    }
  }
}

public struct _SubscribeReducer<Parent: Reducer, TriggerAction, StreamElement, Value>: Reducer {
	@usableFromInline
	let parent: Parent

	@usableFromInline
	let triggerAction: AnyCasePath<Parent.Action, TriggerAction>

	@usableFromInline
  let stream: Stream<Parent.State, StreamElement>

	@usableFromInline
	let operation: Operation<Parent.Action, Value>

	@usableFromInline
	let transform: (StreamElement) -> Value

	init(
		parent: Parent,
		on triggerAction: CaseKeyPath<Parent.Action, TriggerAction>,
    to stream: Stream<Parent.State, StreamElement>,
		with operation: Operation<Parent.Action, Value>,
		transform: @escaping @Sendable (StreamElement) -> Value
	) {
		self.parent = parent
		self.triggerAction = AnyCasePath(triggerAction)
		self.stream = stream
		self.transform = transform
		self.operation = operation
	}

	public func reduce(into state: inout Parent.State, action: Parent.Action) -> Effect<Parent.Action> {
		let effects = parent.reduce(into: &state, action: action)

		guard self.triggerAction.extract(from: action) != nil else {
			return effects
		}
    
		return .merge(
			effects,
			.run { [state = state] send in
        for await value in await stream(state: state) {
					switch operation {
					case .action(let action, let animation):
						await send(action.embed(transform(value)), animation: animation)
					case .operation(let f):
						try await f(send, transform(value))
					}
				}
			}
		)
	}
}
