import ComposableArchitecture

extension Reducer {
	public func subscribe<TriggerAction, T>(
		to stream: @escaping () async -> AsyncStream<T>,
		on triggerAction: CaseKeyPath<Action, TriggerAction>,
		with responseAction: CaseKeyPath<Action, T>
	) -> _SubscribeReducer<Self, TriggerAction, T> {
		.init(
			parent: self,
			on: triggerAction,
			to: stream,
			with: responseAction
		)
	}
}

public struct _SubscribeReducer<Parent: Reducer, TriggerAction, T>: Reducer {
	@usableFromInline
	let parent: Parent

	@usableFromInline
	let triggerAction: AnyCasePath<Parent.Action, TriggerAction>

	@usableFromInline
	let stream: () async -> AsyncStream<T>

	@usableFromInline
	let responseAction: AnyCasePath<Parent.Action, T>

	init(
		parent: Parent,
		on triggerAction: CaseKeyPath<Parent.Action, TriggerAction>,
		to stream: @escaping () async -> AsyncStream<T>,
		with responseAction: CaseKeyPath<Parent.Action, T>
	) {
		self.parent = parent
		self.triggerAction = AnyCasePath(triggerAction)
		self.stream = stream
		self.responseAction = AnyCasePath(responseAction)
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
					await send(responseAction.embed(value))
				}
			}
		)
	}
}
