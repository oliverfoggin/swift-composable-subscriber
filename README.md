# Composable Subscriber

A higher order reducer for subscribing to `AsyncStream` from your app.

A common pattern in our app for shared data is to create a dependency that exposes an `AsyncStream` of the data that is shared.

Then in the `Reducer` on a `task` action we can do soemthing like...

```
Reduce { state, action in
  switch action {
  case .task:
    return { send in
      for await value in await dependency.stream() {
        await send(.responseAction(value))
      }
    }
  }
}
```

When you have a lot of publishers/subscribers this gets very repetetive.

This gives a new way to subscribe to an async stream using a higher order reducer.

Any dependency that returns an `AsyncStream` can be subscribed to in the following way.

# If the action takes the same type as the stream

If the `AsyncStream` `Element` type is the same as the input type of the response action you can just do:

```
Reduce {
 // your usual reducer here
}
.subscribe(
  to: myDependency.stream,
  on: \.some.trigger.action,
  with: \.some.response.actionThatTakesStreamElement
)
``` 

# If the type doesn't match

If the stream `Element` type needs to be transformed you can do:

```
Reduce {
 // your usual reducer here
}
.subscribe(
  to: myDependency.stream,
  on: \.some.trigger.action,
  with: \.response.actionThatTakesAString
) { streamElement in
  // return some type created from the streamElement
  "\(streamElement)"
}
```

# If you have a more complex scenarios and want to run some logic

If you don't necessarily need a response action but you want to do something else like running another dependency or something. You can do:

```
Reduce {
 // your usual reducer here
}
.subscribe(
  to: myDependency.stream,
  on: \.some.trigger.action
) { send, streamElement in
  await send(.responseAction)
  await otherDependency.doSomethingElse(with: streamElement)
}
``` 
