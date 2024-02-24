import ComposableArchitecture
import XCTest
@testable import ComposableSubscriber

@DependencyClient
struct NumberClient {
  var numberStreamWithoutArg: @Sendable () async -> AsyncStream<Int> = { .never }
  var numberStreamWithArg: @Sendable (Int) async -> AsyncStream<Int> = { _ in .never }
}

extension NumberClient: TestDependencyKey {
  
  static var live: NumberClient {
    NumberClient(
      numberStreamWithoutArg: {
        AsyncStream { continuation in
          continuation.yield(1)
          continuation.finish()
        }
      },
      numberStreamWithArg: { number in
        AsyncStream { continuation in
          continuation.yield(number)
          continuation.finish()
        }
      }
    )
  }
  
  static let testValue = Self()
}

extension DependencyValues {
  var numberClient: NumberClient {
    get { self[NumberClient.self] }
    set { self[NumberClient.self] = newValue }
  }
}

struct NumberState: Equatable {
  var number: Int
  var currentNumber: Int?
}

@CasePathable
enum NumberAction {
  case receive(Int)
  case task
}

@Reducer
struct ReducerWithArg {

  typealias State = NumberState
  typealias Action = NumberAction
  
  @Dependency(\.numberClient) var numberClient
  
  var body: some Reducer<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case let .receive(number):
        state.currentNumber = number
        return .none
      case .task:
        return .none
      }
    }
    .subscribe(
      using: \.number,
      to: numberClient.numberStreamWithArg,
      on: \.task,
      with: \.receive
    )
  }
}

@Reducer
struct ReducerWithTransform {

  typealias State = NumberState
  typealias Action = NumberAction
  
  @Dependency(\.numberClient) var numberClient
  
  var body: some Reducer<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case let .receive(number):
        state.currentNumber = number
        return .none
      case .task:
        return .none
      }
    }
    .subscribe(
      using: \.number,
      to: numberClient.numberStreamWithArg,
      on: \.task,
      with: \.receive
    ) {
      $0 * 2
    }
  }
}

@MainActor
final class swift_composable_subscriberTests: XCTestCase {
  
  func testSubscribeWithArg() async throws {
    let store = TestStore(
      initialState: ReducerWithArg.State(number: 19),
      reducer: ReducerWithArg.init
    ) {
      $0.numberClient = .live
    }
    
    let task = await store.send(.task)
    await store.receive(\.receive) {
      $0.currentNumber = 19
    }
    
    await task.cancel()
    await store.finish()
  }
  
  func testSubscribeWithArgAndTransform() async throws {
    let store = TestStore(
      initialState: ReducerWithTransform.State(number: 10),
      reducer: ReducerWithTransform.init
    ) {
      $0.numberClient = .live
    }
    
    let task = await store.send(.task)
    await store.receive(\.receive) {
      $0.currentNumber = 20
    }
    
    await task.cancel()
    await store.finish()
  }
    
}
