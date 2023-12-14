# Composable Subscriber

A higher order reducer for subscribing to `AsyncStream` from your app.

Any dependency that returns an `AsyncStream` can be subscribed to in the following way.

```
Reduce {
 // your usual reducer here
}
.subscribe(on: \.some.trigger.action, to: myDependency.strem, with: \.some.response.action)
``` 

There is a requirement that the AsyncStream returns the same type as the response action takes.
