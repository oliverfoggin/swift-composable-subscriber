import ComposableArchitecture
import SwiftUI

extension Reducer {
	public func subscribe<TriggerAction, StreamElement>(
		to stream: @escaping @Sendable () async -> AsyncStream<StreamElement>,
		on triggerAction: CaseKeyPath<Action, TriggerAction>,
		with responseAction: CaseKeyPath<Action, StreamElement>,
		animation: Animation? = nil
	) -> _SubscribeReducer<Self, TriggerAction, StreamElement, StreamElement> {
		.init(
			parent: self,
			on: triggerAction,
			to: stream,
			with: .action(action: AnyCasePath(responseAction), animation: animation),
			transform: { $0 }
		)
	}

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
			to: stream,
			with: .action(action: AnyCasePath(responseAction), animation: animation),
			transform: transform
		)
	}

	public func subscribe<TriggerAction, StreamElement>(
		to stream: @escaping @Sendable () async -> AsyncStream<StreamElement>,
		on triggerAction: CaseKeyPath<Action, TriggerAction>,
		operation: @escaping @Sendable (_ send: Send<Action>, StreamElement) async throws -> Void
	) -> _SubscribeReducer<Self, TriggerAction, StreamElement, StreamElement> {
		.init(
			parent: self,
			on: triggerAction,
			to: stream,
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

public struct _SubscribeReducer<Parent: Reducer, TriggerAction, StreamElement, Value>: Reducer {
	@usableFromInline
	let parent: Parent

	@usableFromInline
	let triggerAction: AnyCasePath<Parent.Action, TriggerAction>

	@usableFromInline
	let stream: () async -> AsyncStream<StreamElement>

	@usableFromInline
	let operation: Operation<Parent.Action, Value>

	@usableFromInline
	let transform: (StreamElement) -> Value

	init(
		parent: Parent,
		on triggerAction: CaseKeyPath<Parent.Action, TriggerAction>,
		to stream: @escaping @Sendable () async -> AsyncStream<StreamElement>,
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
			.run { send in
				for await value in await stream() {
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
