import 'dart:async';

import 'package:nothin_but_the_bloc/src/subscriber.dart';
import 'package:rxdart/rxdart.dart';

abstract class BlocSubject<E> extends Subject<E> {
  BlocSubject(
    StreamController<E> controller,
    Observable<E> observable,
  ) : super(controller, observable);

  /// Maps each emitted item to a new [Stream] using the given mapper, then
  /// subscribes to each new stream one after the next until all values are
  /// emitted.
  ///
  /// asyncExpand is similar to flatMap, but ensures order by guaranteeing that
  /// all items from the created stream will be emitted before moving to the
  /// next created stream. This process continues until all created streams have
  /// completed.
  ///
  /// This is functionally equivalent to `concatMap`, which exists as an alias
  /// for a more fluent Rx API.
  ///
  /// ### Example
  ///
  ///     Subscriber.range(4, 1)
  ///       .asyncExpand((i) =>
  ///         new Subscriber.timer(i, new Duration(minutes: i))
  ///       .listen(print); // prints 4, 3, 2, 1
  @override
  Subscriber<S> asyncExpand<S>(Stream<S> mapper(E value)) =>
      Subscriber<S>.fromStream(controller.stream.asyncExpand(mapper));

  /// Creates an Subscriber with each data event of this stream asynchronously
  /// mapped to a new event.
  ///
  /// This acts like map, except that convert may return a Future, and in that
  /// case, the stream waits for that future to complete before continuing with
  /// its result.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  @override
  Subscriber<S> asyncMap<S>(FutureOr<S> convert(E value)) =>
      Subscriber<S>.fromStream(controller.stream.asyncMap(convert));

  /// Creates an Subscriber where each item is a [List] containing the items
  /// from the source sequence.
  ///
  /// This [List] is emitted every time [window] emits an event.
  ///
  /// ### Example
  ///
  ///     new Subscriber.periodic(const Duration(milliseconds: 100), (i) => i)
  ///       .buffer(new Stream.periodic(const Duration(milliseconds: 160), (i) => i))
  ///       .listen(print); // prints [0, 1] [2, 3] [4, 5] ...
  @override
  Subscriber<List<E>> buffer(Stream window) =>
      transform(BufferStreamTransformer((_) => window));

  /// Buffers a number of values from the source Subscriber by [count] then
  /// emits the buffer and clears it, and starts a new buffer each
  /// [startBufferEvery] values. If [startBufferEvery] is not provided,
  /// then new buffers are started immediately at the start of the source
  /// and when each buffer closes and is emitted.
  ///
  /// ### Example
  /// [count] is the maximum size of the buffer emitted
  ///
  ///     Subscriber.range(1, 4)
  ///       .bufferCount(2)
  ///       .listen(print); // prints [1, 2], [3, 4] done!
  ///
  /// ### Example
  /// if [startBufferEvery] is 2, then a new buffer will be started
  /// on every other value from the source. A new buffer is started at the
  /// beginning of the source by default.
  ///
  ///     Subscriber.range(1, 5)
  ///       .bufferCount(3, 2)
  ///       .listen(print); // prints [1, 2, 3], [3, 4, 5], [5] done!
  @override
  Subscriber<List<E>> bufferCount(int count, [int startBufferEvery = 0]) =>
      transform(BufferCountStreamTransformer<E>(count, startBufferEvery));

  /// Creates an Subscriber where each item is a [List] containing the items
  /// from the source sequence, batched whenever test passes.
  ///
  /// ### Example
  ///
  ///     new Subscriber.periodic(const Duration(milliseconds: 100), (int i) => i)
  ///       .bufferTest((i) => i % 2 == 0)
  ///       .listen(print); // prints [0], [1, 2] [3, 4] [5, 6] ...
  @override
  Subscriber<List<E>> bufferTest(bool onTestHandler(E event)) =>
      transform(BufferTestStreamTransformer<E>(onTestHandler));

  /// Creates an Subscriber where each item is a [List] containing the items
  /// from the source sequence, sampled on a time frame with [duration].
  ///
  /// ### Example
  ///
  ///     new Subscriber.periodic(const Duration(milliseconds: 100), (int i) => i)
  ///       .bufferTime(const Duration(milliseconds: 220))
  ///       .listen(print); // prints [0, 1] [2, 3] [4, 5] ...
  @override
  Subscriber<List<E>> bufferTime(Duration duration) {
    if (duration == null) throw ArgumentError.notNull('duration');

    return buffer(Stream<void>.periodic(duration));
  }

  ///
  /// Adapt this stream to be a `Stream<R>`.
  ///
  /// If this stream already has the desired type, its returned directly.
  /// Otherwise it is wrapped as a `Stream<R>` which checks at run-time that
  /// each data event emitted by this stream is also an instance of [R].
  ///
  @override
  Subscriber<R> cast<R>() =>
      Subscriber<R>.fromStream(controller.stream.cast<R>());

  /// Maps each emitted item to a new [Stream] using the given mapper, then
  /// subscribes to each new stream one after the next until all values are
  /// emitted.
  ///
  /// ConcatMap is similar to flatMap, but ensures order by guaranteeing that
  /// all items from the created stream will be emitted before moving to the
  /// next created stream. This process continues until all created streams have
  /// completed.
  ///
  /// This is a simple alias for Dart Stream's `asyncExpand`, but is included to
  /// ensure a more consistent Rx API.
  ///
  /// ### Example
  ///
  ///     Subscriber.range(4, 1)
  ///       .concatMap((i) =>
  ///         new Subscriber.timer(i, new Duration(minutes: i))
  ///       .listen(print); // prints 4, 3, 2, 1
  @override
  Subscriber<S> concatMap<S>(Stream<S> mapper(E value)) =>
      Subscriber<S>.fromStream(controller.stream.asyncExpand(mapper));

  /// Returns an Subscriber that emits all items from the current Subscriber,
  /// then emits all items from the given observable, one after the next.
  ///
  /// ### Example
  ///
  ///     new Subscriber.timer(1, new Duration(seconds: 10))
  ///         .concatWith([new Subscriber.just(2)])
  ///         .listen(print); // prints 1, 2
  @override
  Subscriber<E> concatWith(Iterable<Stream<E>> other) =>
      Subscriber<E>.fromStream(
          ConcatStream<E>(<Stream<E>>[controller.stream]..addAll(other)));

  /// Transforms a [Stream] so that will only emit items from the source sequence
  /// if a [window] has completed, without the source sequence emitting
  /// another item.
  ///
  /// This [window] is created after the last debounced event was emitted.
  /// You can use the value of the last debounced event to determine
  /// the length of the next [window].
  ///
  /// A [window] is open until the first [window] event emits.
  ///
  /// debounce filters out items emitted by the source [Subscriber]
  /// that are rapidly followed by another emitted item.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#debounce)
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2, 3, 4])
  ///       .debounce((_) => TimerStream(true, const Duration(seconds: 1)))
  ///       .listen(print); // prints 4
  @override
  Subscriber<E> debounce(Stream window(E event)) =>
      transform(DebounceStreamTransformer<E>(window));

  /// Transforms a [Stream] so that will only emit items from the source sequence
  /// whenever the time span defined by [duration] passes,
  /// without the source sequence emitting another item.
  ///
  /// This time span start after the last debounced event was emitted.
  ///
  /// debounceTime filters out items emitted by the source [Subscriber]
  /// that are rapidly followed by another emitted item.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#debounce)
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2, 3, 4])
  ///       .debounceTime(const Duration(seconds: 1))
  ///       .listen(print); // prints 4
  @override
  Subscriber<E> debounceTime(Duration duration) => transform(
      DebounceStreamTransformer<E>((_) => TimerStream<bool>(true, duration)));

  /// Emit items from the source Stream, or a single default item if the source
  /// Stream emits nothing.
  ///
  /// ### Example
  ///
  ///     new Subscriber.empty().defaultIfEmpty(10).listen(print); // prints 10
  @override
  Subscriber<E> defaultIfEmpty(E defaultValue) =>
      transform(DefaultIfEmptyStreamTransformer<E>(defaultValue));

  /// The Delay operator modifies its source Subscriber by pausing for
  /// a particular increment of time (that you specify) before emitting
  /// each of the source Subscriber’s items.
  /// This has the effect of shifting the entire sequence of items emitted
  /// by the Subscriber forward in time by that specified increment.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#delay)
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2, 3, 4])
  ///       .delay(new Duration(seconds: 1))
  ///       .listen(print); // [after one second delay] prints 1, 2, 3, 4 immediately
  @override
  Subscriber<E> delay(Duration duration) =>
      transform(DelayStreamTransformer<E>(duration));

  /// Converts the onData, onDone, and onError [Notification] objects from a
  /// materialized stream into normal onData, onDone, and onError events.
  ///
  /// When a stream has been materialized, it emits onData, onDone, and onError
  /// events as [Notification] objects. Dematerialize simply reverses this by
  /// transforming [Notification] objects back to a normal stream of events.
  ///
  /// ### Example
  ///
  ///     new Subscriber<Notification<int>>
  ///         .fromIterable([new Notification.onData(1), new Notification.onDone()])
  ///         .dematerialize()
  ///         .listen((i) => print(i)); // Prints 1
  ///
  /// ### Error example
  ///
  ///     new Subscriber<Notification<int>>
  ///         .just(new Notification.onError(new Exception(), null))
  ///         .dematerialize()
  ///         .listen(null, onError: (e, s) { print(e) }); // Prints Exception
  @override
  Subscriber<S> dematerialize<S>() {
    return cast<Notification<S>>()
        .transform(DematerializeStreamTransformer<S>());
  }

  /// WARNING: More commonly known as distinctUntilChanged in other Rx
  /// implementations. Creates an Subscriber where data events are skipped if
  /// they are equal to the previous data event.
  ///
  /// The returned stream provides the same events as this stream, except that
  /// it never provides two consecutive data events that are equal.
  ///
  /// Equality is determined by the provided equals method. If that is omitted,
  /// the '==' operator on the last provided data element is used.
  ///
  /// The returned stream is a broadcast stream if this stream is. If a
  /// broadcast stream is listened to more than once, each subscription will
  /// individually perform the equals test.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#distinctUntilChanged)
  @override
  Subscriber<E> distinct([bool equals(E previous, E next)]) =>
      Subscriber<E>.fromStream(controller.stream.distinct(equals));

  /// WARNING: More commonly known as distinct in other Rx implementations.
  /// Creates an Subscriber where data events are skipped if they have already
  /// been emitted before.
  ///
  /// Equality is determined by the provided equals and hashCode methods.
  /// If these are omitted, the '==' operator and hashCode on the last provided
  /// data element are used.
  ///
  /// The returned stream is a broadcast stream if this stream is. If a
  /// broadcast stream is listened to more than once, each subscription will
  /// individually perform the equals and hashCode tests.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#distinct)
  @override
  Subscriber<E> distinctUnique({bool equals(E e1, E e2), int hashCode(E e)}) =>
      transform(DistinctUniqueStreamTransformer<E>(
          equals: equals, hashCode: hashCode));

  /// Invokes the given callback function when the stream subscription is
  /// cancelled. Often called doOnUnsubscribe or doOnDispose in other
  /// implementations.
  ///
  /// ### Example
  ///
  ///     final subscription = new Subscriber.timer(1, new Duration(minutes: 1))
  ///       .doOnCancel(() => print("hi"));
  ///       .listen(null);
  ///
  ///     subscription.cancel(); // prints "hi"
  @override
  Subscriber<E> doOnCancel(void onCancel()) =>
      transform(DoStreamTransformer<E>(onCancel: onCancel));

  /// Invokes the given callback function when the stream emits an item. In
  /// other implementations, this is called doOnNext.
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2, 3])
  ///       .doOnData(print)
  ///       .listen(null); // prints 1, 2, 3
  @override
  Subscriber<E> doOnData(void onData(E event)) =>
      transform(DoStreamTransformer<E>(onData: onData));

  /// Invokes the given callback function when the stream finishes emitting
  /// items. In other implementations, this is called doOnComplete(d).
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2, 3])
  ///       .doOnDone(() => print("all set"))
  ///       .listen(null); // prints "all set"
  @override
  Subscriber<E> doOnDone(void onDone()) =>
      transform(DoStreamTransformer<E>(onDone: onDone));

  /// Invokes the given callback function when the stream emits data, emits
  /// an error, or emits done. The callback receives a [Notification] object.
  ///
  /// The [Notification] object contains the [Kind] of event (OnData, onDone,
  /// or OnError), and the item or error that was emitted. In the case of
  /// onDone, no data is emitted as part of the [Notification].
  ///
  /// ### Example
  ///
  ///     new Subscriber.just(1)
  ///       .doOnEach(print)
  ///       .listen(null); // prints Notification{kind: OnData, value: 1, errorAndStackTrace: null}, Notification{kind: OnDone, value: null, errorAndStackTrace: null}
  @override
  Subscriber<E> doOnEach(void onEach(Notification<E> notification)) =>
      transform(DoStreamTransformer<E>(onEach: onEach));

  /// Invokes the given callback function when the stream emits an error.
  ///
  /// ### Example
  ///
  ///     new Subscriber.error(new Exception())
  ///       .doOnError((error, stacktrace) => print("oh no"))
  ///       .listen(null); // prints "Oh no"
  @override
  Subscriber<E> doOnError(Function onError) =>
      transform(DoStreamTransformer<E>(onError: onError));

  /// Invokes the given callback function when the stream is first listened to.
  ///
  /// ### Example
  ///
  ///     new Subscriber.just(1)
  ///       .doOnListen(() => print("Is someone there?"))
  ///       .listen(null); // prints "Is someone there?"
  @override
  Subscriber<E> doOnListen(void onListen()) =>
      transform(DoStreamTransformer<E>(onListen: onListen));

  /// Invokes the given callback function when the stream subscription is
  /// paused.
  ///
  /// ### Example
  ///
  ///     final subscription = new Subscriber.just(1)
  ///       .doOnPause(() => print("Gimme a minute please"))
  ///       .listen(null);
  ///
  ///     subscription.pause(); // prints "Gimme a minute please"
  @override
  Subscriber<E> doOnPause(void onPause(Future<dynamic> resumeSignal)) =>
      transform(DoStreamTransformer<E>(onPause: onPause));

  /// Invokes the given callback function when the stream subscription
  /// resumes receiving items.
  ///
  /// ### Example
  ///
  ///     final subscription = new Subscriber.just(1)
  ///       .doOnResume(() => print("Let's do this!"))
  ///       .listen(null);
  ///
  ///     subscription.pause();
  ///     subscription.resume(); "Let's do this!"
  @override
  Subscriber<E> doOnResume(void onResume()) =>
      transform(DoStreamTransformer<E>(onResume: onResume));

  /// Converts items from the source stream into a new Stream using a given
  /// mapper. It ignores all items from the source stream until the new stream
  /// completes.
  ///
  /// Useful when you have a noisy source Stream and only want to respond once
  /// the previous async operation is finished.
  ///
  /// ### Example
  ///
  ///     Subscriber.range(0, 2).interval(new Duration(milliseconds: 50))
  ///       .exhaustMap((i) =>
  ///         new Subscriber.timer(i, new Duration(milliseconds: 75)))
  ///       .listen(print); // prints 0, 2
  @override
  Subscriber<S> exhaustMap<S>(Stream<S> mapper(E value)) =>
      transform(ExhaustMapStreamTransformer<E, S>(mapper));

  /// Creates an Subscriber from this stream that converts each element into
  /// zero or more events.
  ///
  /// Each incoming event is converted to an Iterable of new events, and each of
  /// these new events are then sent by the returned Subscriber in order.
  ///
  /// The returned Subscriber is a broadcast stream if this stream is. If a
  /// broadcast stream is listened to more than once, each subscription will
  /// individually call convert and expand the events.
  @override
  Subscriber<S> expand<S>(Iterable<S> convert(E value)) =>
      Subscriber<S>.fromStream(controller.stream.expand(convert));

  /// Converts each emitted item into a new Stream using the given mapper
  /// function. The newly created Stream will be be listened to and begin
  /// emitting items downstream.
  ///
  /// The items emitted by each of the new Streams are emitted downstream in the
  /// same order they arrive. In other words, the sequences are merged
  /// together.
  ///
  /// ### Example
  ///
  ///     Subscriber.range(4, 1)
  ///       .flatMap((i) =>
  ///         new Subscriber.timer(i, new Duration(minutes: i))
  ///       .listen(print); // prints 1, 2, 3, 4
  @override
  Subscriber<S> flatMap<S>(Stream<S> mapper(E value)) =>
      transform(FlatMapStreamTransformer<E, S>(mapper));

  /// Converts each item into a new Stream. The Stream must return an
  /// Iterable. Then, each item from the Iterable will be emitted one by one.
  ///
  /// Use case: you may have an API that returns a list of items, such as
  /// a Stream<List<String>>. However, you might want to operate on the individual items
  /// rather than the list itself. This is the job of `flatMapIterable`.
  ///
  /// ### Example
  ///
  ///     Subscriber.range(1, 4)
  ///       .flatMapIterable((i) =>
  ///         new Subscriber.just([i])
  ///       .listen(print); // prints 1, 2, 3, 4
  @override
  Subscriber<S> flatMapIterable<S>(Stream<Iterable<S>> mapper(E value)) =>
      transform(FlatMapStreamTransformer<E, Iterable<S>>(mapper))
          .expand((Iterable<S> iterable) => iterable);

  /// The GroupBy operator divides an [Subscriber] that emits items into
  /// an [Subscriber] that emits [GroupBySubscriber],
  /// each one of which emits some subset of the items
  /// from the original source [Subscriber].
  ///
  /// [GroupBySubscriber] acts like a regular [Subscriber], yet
  /// adding a 'key' property, which receives its [Type] and value from
  /// the [grouper] Function.
  ///
  /// All items with the same key are emitted by the same [GroupBySubscriber].
  @override
  Subscriber<GroupByObservable<E, S>> groupBy<S>(S grouper(E value)) =>
      transform(GroupByStreamTransformer<E, S>(grouper));

  /// Creates a wrapper Stream that intercepts some errors from this stream.
  ///
  /// If this stream sends an error that matches test, then it is intercepted by
  /// the handle function.
  ///
  /// The onError callback must be of type void onError(error) or void
  /// onError(error, StackTrace stackTrace). Depending on the function type the
  /// stream either invokes onError with or without a stack trace. The stack
  /// trace argument might be null if the stream itself received an error
  /// without stack trace.
  ///
  /// An asynchronous error e is matched by a test function if test(e) returns
  /// true. If test is omitted, every error is considered matching.
  ///
  /// If the error is intercepted, the handle function can decide what to do
  /// with it. It can throw if it wants to raise a new (or the same) error, or
  /// simply return to make the stream forget the error.
  ///
  /// If you need to transform an error into a data event, use the more generic
  /// Stream.transform to handle the event by writing a data event to the output
  /// sink.
  ///
  /// The returned stream is a broadcast stream if this stream is. If a
  /// broadcast stream is listened to more than once, each subscription will
  /// individually perform the test and handle the error.
  @override
  Subscriber<E> handleError(Function onError, {bool test(dynamic error)}) =>
      Subscriber<E>.fromStream(
          controller.stream.handleError(onError, test: test));

  /// Creates an Subscriber where all emitted items are ignored, only the
  /// error / completed notifications are passed
  ///
  /// ### Example
  ///
  ///    new Subscriber.merge([
  ///      new Subscriber.just(1),
  ///      new Subscriber.error(new Exception())
  ///    ])
  ///    .listen(print, onError: print); // prints Exception
  @override
  Subscriber<E> ignoreElements() =>
      transform(IgnoreElementsStreamTransformer<E>());

  /// Creates an Subscriber that emits each item in the Stream after a given
  /// duration.
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2, 3])
  ///       .interval(new Duration(seconds: 1))
  ///       .listen((i) => print("$i sec"); // prints 1 sec, 2 sec, 3 sec
  @override
  Subscriber<E> interval(Duration duration) =>
      transform(IntervalStreamTransformer<E>(duration));

  /// Maps values from a source sequence through a function and emits the
  /// returned values.
  ///
  /// The returned sequence completes when the source sequence completes.
  /// The returned sequence throws an error if the source sequence throws an
  /// error.
  @override
  Subscriber<S> map<S>(S convert(E event)) =>
      Subscriber<S>.fromStream(controller.stream.map(convert));

  /// Emits the given constant value on the output Subscriber every time the source Subscriber emits a value.
  ///
  /// ### Example
  ///
  ///     Subscriber.fromIterable([1, 2, 3, 4])
  ///       .mapTo(true)
  ///       .listen(print); // prints true, true, true, true
  @override
  Subscriber<S> mapTo<S>(S value) =>
      transform(MapToStreamTransformer<E, S>(value));

  /// Converts the onData, on Done, and onError events into [Notification]
  /// objects that are passed into the downstream onData listener.
  ///
  /// The [Notification] object contains the [Kind] of event (OnData, onDone, or
  /// OnError), and the item or error that was emitted. In the case of onDone,
  /// no data is emitted as part of the [Notification].
  ///
  /// Example:
  ///     new Subscriber<int>.just(1)
  ///         .materialize()
  ///         .listen((i) => print(i)); // Prints onData & onDone Notification
  ///
  ///     new Subscriber<int>.error(new Exception())
  ///         .materialize()
  ///         .listen((i) => print(i)); // Prints onError Notification
  @override
  Subscriber<Notification<E>> materialize() =>
      transform(MaterializeStreamTransformer<E>());

  /// Combines the items emitted by multiple streams into a single stream of
  /// items. The items are emitted in the order they are emitted by their
  /// sources.
  ///
  /// ### Example
  ///
  ///     new Subscriber.timer(1, new Duration(seconds: 10))
  ///         .mergeWith([new Subscriber.just(2)])
  ///         .listen(print); // prints 2, 1
  @override
  Subscriber<E> mergeWith(Iterable<Stream<E>> streams) =>
      Subscriber<E>.fromStream(
          MergeStream<E>(<Stream<E>>[controller.stream]..addAll(streams)));

  /// Filters a sequence so that only events of a given type pass
  ///
  /// In order to capture the Type correctly, it needs to be wrapped
  /// in a [TypeToken] as the generic parameter.
  ///
  /// Given the way Dart generics work, one cannot simply use the `is T` / `as T`
  /// checks and castings with this method alone. Therefore, the
  /// [TypeToken] class was introduced to capture the type of class you'd
  /// like `ofType` to filter down to.
  ///
  /// ### Examples
  ///
  ///     new Subscriber.fromIterable([1, "hi"])
  ///       .ofType(new TypeToken<String>)
  ///       .listen(print); // prints "hi"
  ///
  /// As a shortcut, you can use some pre-defined constants to write the above
  /// in the following way:
  ///
  ///     new Subscriber.fromIterable([1, "hi"])
  ///       .ofType(kString)
  ///       .listen(print); // prints "hi"
  ///
  /// If you'd like to create your own shortcuts like the example above,
  /// simply create a constant:
  ///
  ///     const TypeToken<Map<Int, String>> kMapIntString =
  ///       const TypeToken<Map<Int, String>>();
  @override
  Subscriber<S> ofType<S>(TypeToken<S> typeToken) =>
      transform(OfTypeStreamTransformer<E, S>(typeToken));

  /// Intercepts error events and switches to the given recovery stream in
  /// that case
  ///
  /// The onErrorResumeNext operator intercepts an onError notification from
  /// the source Subscriber. Instead of passing the error through to any
  /// listeners, it replaces it with another Stream of items.
  ///
  /// If you need to perform logic based on the type of error that was emitted,
  /// please consider using [onErrorResume].
  ///
  /// ### Example
  ///
  ///     new Subscriber.error(new Exception())
  ///       .onErrorResumeNext(new Subscriber.fromIterable([1, 2, 3]))
  ///       .listen(print); // prints 1, 2, 3
  @override
  Subscriber<E> onErrorResumeNext(Stream<E> recoveryStream) => transform(
      OnErrorResumeStreamTransformer<E>((dynamic e) => recoveryStream));

  /// Intercepts error events and switches to a recovery stream created by the
  /// provided [recoveryFn].
  ///
  /// The onErrorResume operator intercepts an onError notification from
  /// the source Subscriber. Instead of passing the error through to any
  /// listeners, it replaces it with another Stream of items created by the
  /// [recoveryFn].
  ///
  /// The [recoveryFn] receives the emitted error and returns a Stream. You can
  /// perform logic in the [recoveryFn] to return different Streams based on the
  /// type of error that was emitted.
  ///
  /// If you do not need to perform logic based on the type of error that was
  /// emitted, please consider using [onErrorResumeNext] or [onErrorReturn].
  ///
  /// ### Example
  ///
  ///     new Subscriber<int>.error(new Exception())
  ///       .onErrorResume((dynamic e) =>
  ///           new Subscriber.just(e is StateError ? 1 : 0)
  ///       .listen(print); // prints 0
  @override
  Subscriber<E> onErrorResume(Stream<E> Function(dynamic error) recoveryFn) =>
      transform(OnErrorResumeStreamTransformer<E>(recoveryFn));

  /// instructs an Subscriber to emit a particular item when it encounters an
  /// error, and then terminate normally
  ///
  /// The onErrorReturn operator intercepts an onError notification from
  /// the source Subscriber. Instead of passing it through to any observers, it
  /// replaces it with a given item, and then terminates normally.
  ///
  /// If you need to perform logic based on the type of error that was emitted,
  /// please consider using [onErrorReturnWith].
  ///
  /// ### Example
  ///
  ///     new Subscriber.error(new Exception())
  ///       .onErrorReturn(1)
  ///       .listen(print); // prints 1
  @override
  Subscriber<E> onErrorReturn(E returnValue) =>
      transform(OnErrorResumeStreamTransformer<E>(
          (dynamic e) => Subscriber<E>.just(returnValue)));

  /// instructs an Subscriber to emit a particular item created by the
  /// [returnFn] when it encounters an error, and then terminate normally.
  ///
  /// The onErrorReturnWith operator intercepts an onError notification from
  /// the source Subscriber. Instead of passing it through to any observers, it
  /// replaces it with a given item, and then terminates normally.
  ///
  /// The [returnFn] receives the emitted error and returns a Stream. You can
  /// perform logic in the [returnFn] to return different Streams based on the
  /// type of error that was emitted.
  ///
  /// If you do not need to perform logic based on the type of error that was
  /// emitted, please consider using [onErrorReturn].
  ///
  /// ### Example
  ///
  ///     new Subscriber.error(new Exception())
  ///       .onErrorReturnWith((e) => e is Exception ? 1 : 0)
  ///       .listen(print); // prints 1
  @override
  Subscriber<E> onErrorReturnWith(E Function(dynamic error) returnFn) =>
      transform(OnErrorResumeStreamTransformer<E>(
          (dynamic e) => Subscriber<E>.just(returnFn(e))));

  /// Emits the n-th and n-1th events as a pair..
  ///
  /// ### Example
  ///
  ///     Subscriber.range(1, 4)
  ///       .pairwise()
  ///       .listen(print); // prints [1, 2], [2, 3], [3, 4]
  @override
  Subscriber<Iterable<E>> pairwise() => transform(PairwiseStreamTransformer());

  /// Emits the most recently emitted item (if any)
  /// emitted by the source [Stream] since the previous emission from
  /// the [sampleStream].
  ///
  /// ### Example
  ///
  ///     new Stream.fromIterable([1, 2, 3])
  ///       .sample(new TimerStream(1, const Duration(seconds: 1)))
  ///       .listen(print); // prints 3
  @override
  Subscriber<E> sample(Stream<dynamic> sampleStream) =>
      transform(SampleStreamTransformer<E>((_) => sampleStream));

  /// Emits the most recently emitted item (if any)
  /// emitted by the source [Stream] since the previous emission within
  /// the recurring time span, defined by [duration]
  ///
  /// ### Example
  ///
  ///     new Stream.fromIterable([1, 2, 3])
  ///       .sampleTime(const Duration(seconds: 1))
  ///       .listen(print); // prints 3
  @override
  Subscriber<E> sampleTime(Duration duration) =>
      sample(Stream<void>.periodic(duration));

  /// Applies an accumulator function over an observable sequence and returns
  /// each intermediate result. The optional seed value is used as the initial
  /// accumulator value.
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2, 3])
  ///        .scan((acc, curr, i) => acc + curr, 0)
  ///        .listen(print); // prints 1, 3, 6
  @override
  Subscriber<S> scan<S>(S accumulator(S accumulated, E value, int index),
          [S seed]) =>
      transform(ScanStreamTransformer<E, S>(accumulator, seed));

  /// Skips the first count data events from this stream.
  ///
  /// The returned stream is a broadcast stream if this stream is. For a
  /// broadcast stream, the events are only counted from the time the returned
  /// stream is listened to.
  @override
  Subscriber<E> skip(int count) =>
      Subscriber<E>.fromStream(controller.stream.skip(count));

  /// Starts emitting items only after the given stream emits an item.
  ///
  /// ### Example
  ///
  ///     new Subscriber.merge([
  ///         new Subscriber.just(1),
  ///         new Subscriber.timer(2, new Duration(minutes: 2))
  ///       ])
  ///       .skipUntil(new Subscriber.timer(true, new Duration(minutes: 1)))
  ///       .listen(print); // prints 2;
  @override
  Subscriber<E> skipUntil<S>(Stream<S> otherStream) =>
      transform(SkipUntilStreamTransformer<E, S>(otherStream));

  /// Skip data events from this stream while they are matched by test.
  ///
  /// Error and done events are provided by the returned stream unmodified.
  ///
  /// Starting with the first data event where test returns false for the event
  /// data, the returned stream will have the same events as this stream.
  ///
  /// The returned stream is a broadcast stream if this stream is. For a
  /// broadcast stream, the events are only tested from the time the returned
  /// stream is listened to.
  @override
  Subscriber<E> skipWhile(bool test(E element)) =>
      Subscriber<E>.fromStream(controller.stream.skipWhile(test));

  /// Prepends a value to the source Subscriber.
  ///
  /// ### Example
  ///
  ///     new Subscriber.just(2).startWith(1).listen(print); // prints 1, 2
  @override
  Subscriber<E> startWith(E startValue) =>
      transform(StartWithStreamTransformer<E>(startValue));

  /// Prepends a sequence of values to the source Subscriber.
  ///
  /// ### Example
  ///
  ///     new Subscriber.just(3).startWithMany([1, 2])
  ///       .listen(print); // prints 1, 2, 3
  @override
  Subscriber<E> startWithMany(List<E> startValues) =>
      transform(StartWithManyStreamTransformer<E>(startValues));

  /// When the original observable emits no items, this operator subscribes to
  /// the given fallback stream and emits items from that observable instead.
  ///
  /// This can be particularly useful when consuming data from multiple sources.
  /// For example, when using the Repository Pattern. Assuming you have some
  /// data you need to load, you might want to start with the fastest access
  /// point and keep falling back to the slowest point. For example, first query
  /// an in-memory database, then a database on the file system, then a network
  /// call if the data isn't on the local machine.
  ///
  /// This can be achieved quite simply with switchIfEmpty!
  ///
  /// ### Example
  ///
  ///     // Let's pretend we have some Data sources that complete without emitting
  ///     // any items if they don't contain the data we're looking for
  ///     Subscriber<Data> memory;
  ///     Subscriber<Data> disk;
  ///     Subscriber<Data> network;
  ///
  ///     // Start with memory, fallback to disk, then fallback to network.
  ///     // Simple as that!
  ///     Subscriber<Data> getThatData =
  ///         memory.switchIfEmpty(disk).switchIfEmpty(network);
  @override
  Subscriber<E> switchIfEmpty(Stream<E> fallbackStream) =>
      transform(SwitchIfEmptyStreamTransformer<E>(fallbackStream));

  /// Converts each emitted item into a new Stream using the given mapper
  /// function. The newly created Stream will be be listened to and begin
  /// emitting items, and any previously created Stream will stop emitting.
  ///
  /// The switchMap operator is similar to the flatMap and concatMap methods,
  /// but it only emits items from the most recently created Stream.
  ///
  /// This can be useful when you only want the very latest state from
  /// asynchronous APIs, for example.
  ///
  /// ### Example
  ///
  ///     Subscriber.range(4, 1)
  ///       .switchMap((i) =>
  ///         new Subscriber.timer(i, new Duration(minutes: i))
  ///       .listen(print); // prints 1
  @override
  Subscriber<S> switchMap<S>(Stream<S> mapper(E value)) =>
      transform(SwitchMapStreamTransformer<E, S>(mapper));

  /// Provides at most the first `n` values of this stream.
  /// Forwards the first n data events of this stream, and all error events, to
  /// the returned stream, and ends with a done event.
  ///
  /// If this stream produces fewer than count values before it's done, so will
  /// the returned stream.
  ///
  /// Stops listening to the stream after the first n elements have been
  /// received.
  ///
  /// Internally the method cancels its subscription after these elements. This
  /// means that single-subscription (non-broadcast) streams are closed and
  /// cannot be reused after a call to this method.
  ///
  /// The returned stream is a broadcast stream if this stream is. For a
  /// broadcast stream, the events are only counted from the time the returned
  /// stream is listened to
  @override
  Subscriber<E> take(int count) =>
      Subscriber<E>.fromStream(controller.stream.take(count));

  /// Returns the values from the source observable sequence until the other
  /// observable sequence produces a value.
  ///
  /// ### Example
  ///
  ///     new Subscriber.merge([
  ///         new Subscriber.just(1),
  ///         new Subscriber.timer(2, new Duration(minutes: 1))
  ///       ])
  ///       .takeUntil(new Subscriber.timer(3, new Duration(seconds: 10)))
  ///       .listen(print); // prints 1
  @override
  Subscriber<E> takeUntil<S>(Stream<S> otherStream) =>
      transform(TakeUntilStreamTransformer<E, S>(otherStream));

  /// Forwards data events while test is successful.
  ///
  /// The returned stream provides the same events as this stream as long as
  /// test returns true for the event data. The stream is done when either this
  /// stream is done, or when this stream first provides a value that test
  /// doesn't accept.
  ///
  /// Stops listening to the stream after the accepted elements.
  ///
  /// Internally the method cancels its subscription after these elements. This
  /// means that single-subscription (non-broadcast) streams are closed and
  /// cannot be reused after a call to this method.
  ///
  /// The returned stream is a broadcast stream if this stream is. For a
  /// broadcast stream, the events are only tested from the time the returned
  /// stream is listened to.
  @override
  Subscriber<E> takeWhile(bool test(E element)) =>
      Subscriber<E>.fromStream(controller.stream.takeWhile(test));

  /// Emits only the first item emitted by the source [Stream]
  /// while [window] is open.
  ///
  /// if [trailing] is true, then the last item is emitted instead
  ///
  /// You can use the value of the last throttled event to determine
  /// the length of the next [window].
  ///
  /// ### Example
  ///
  ///     new Stream.fromIterable([1, 2, 3])
  ///       .throttle((_) => TimerStream(true, const Duration(seconds: 1)))
  @override
  Subscriber<E> throttle(Stream window(E event), {bool trailing = false}) =>
      transform(ThrottleStreamTransformer<E>(window, trailing: trailing));

  /// Emits only the first item emitted by the source [Stream]
  /// within a time span of [duration].
  ///
  /// if [trailing] is true, then the last item is emitted instead
  ///
  /// ### Example
  ///
  ///     new Stream.fromIterable([1, 2, 3])
  ///       .throttleTime(const Duration(seconds: 1))
  @override
  Subscriber<E> throttleTime(Duration duration, {bool trailing = false}) =>
      transform(ThrottleStreamTransformer<E>(
          (_) => TimerStream<bool>(true, duration),
          trailing: trailing));

  /// Records the time interval between consecutive values in an observable
  /// sequence.
  ///
  /// ### Example
  ///
  ///     new Subscriber.just(1)
  ///       .interval(new Duration(seconds: 1))
  ///       .timeInterval()
  ///       .listen(print); // prints TimeInterval{interval: 0:00:01, value: 1}
  @override
  Subscriber<TimeInterval<E>> timeInterval() =>
      transform(TimeIntervalStreamTransformer<E>());

  /// The Timeout operator allows you to abort an Subscriber with an onError
  /// termination if that Subscriber fails to emit any items during a specified
  /// duration.  You may optionally provide a callback function to execute on
  /// timeout.
  @override
  Subscriber<E> timeout(Duration timeLimit,
          {void onTimeout(EventSink<E> sink)}) =>
      Subscriber<E>.fromStream(
          controller.stream.timeout(timeLimit, onTimeout: onTimeout));

  /// Wraps each item emitted by the source Subscriber in a [Timestamped] object
  /// that includes the emitted item and the time when the item was emitted.
  ///
  /// Example
  ///
  ///     new Subscriber.just(1)
  ///        .timestamp()
  ///        .listen((i) => print(i)); // prints 'TimeStamp{timestamp: XXX, value: 1}';
  @override
  Subscriber<Timestamped<E>> timestamp() {
    return transform(TimestampStreamTransformer<E>());
  }

  /// Filters the elements of an observable sequence based on the test.
  @override
  Subscriber<E> where(bool test(E event)) =>
      Subscriber<E>.fromStream(controller.stream.where(test));

  /// Creates an Subscriber where each item is a [Stream] containing the items
  /// from the source sequence.
  ///
  /// This [List] is emitted every time [window] emits an event.
  ///
  /// ### Example
  ///
  ///     new Subscriber.periodic(const Duration(milliseconds: 100), (i) => i)
  ///       .window(new Stream.periodic(const Duration(milliseconds: 160), (i) => i))
  ///       .asyncMap((stream) => stream.toList())
  ///       .listen(print); // prints [0, 1] [2, 3] [4, 5] ...
  @override
  Subscriber<Stream<E>> window(Stream window) =>
      transform(WindowStreamTransformer((_) => window));

  /// Buffers a number of values from the source Subscriber by [count] then
  /// emits the buffer as a [Stream] and clears it, and starts a new buffer each
  /// [startBufferEvery] values. If [startBufferEvery] is not provided,
  /// then new buffers are started immediately at the start of the source
  /// and when each buffer closes and is emitted.
  ///
  /// ### Example
  /// [count] is the maximum size of the buffer emitted
  ///
  ///     Subscriber.range(1, 4)
  ///       .windowCount(2)
  ///       .asyncMap((stream) => stream.toList())
  ///       .listen(print); // prints [1, 2], [3, 4] done!
  ///
  /// ### Example
  /// if [startBufferEvery] is 2, then a new buffer will be started
  /// on every other value from the source. A new buffer is started at the
  /// beginning of the source by default.
  ///
  ///     Subscriber.range(1, 5)
  ///       .bufferCount(3, 2)
  ///       .listen(print); // prints [1, 2, 3], [3, 4, 5], [5] done!
  @override
  Subscriber<Stream<E>> windowCount(int count, [int startBufferEvery = 0]) =>
      transform(WindowCountStreamTransformer(count, startBufferEvery));

  /// Creates an Subscriber where each item is a [Stream] containing the items
  /// from the source sequence, batched whenever test passes.
  ///
  /// ### Example
  ///
  ///     new Subscriber.periodic(const Duration(milliseconds: 100), (int i) => i)
  ///       .windowTest((i) => i % 2 == 0)
  ///       .asyncMap((stream) => stream.toList())
  ///       .listen(print); // prints [0], [1, 2] [3, 4] [5, 6] ...
  @override
  Subscriber<Stream<E>> windowTest(bool onTestHandler(E event)) =>
      transform(WindowTestStreamTransformer(onTestHandler));

  /// Creates an Subscriber where each item is a [Stream] containing the items
  /// from the source sequence, sampled on a time frame with [duration].
  ///
  /// ### Example
  ///
  ////     new Subscriber.periodic(const Duration(milliseconds: 100), (int i) => i)
  ///       .windowTime(const Duration(milliseconds: 220))
  ///       .doOnData((_) => print('next window'))
  ///       .flatMap((s) => s)
  ///       .listen(print); // prints next window 0, 1, next window 2, 3, ...
  @override
  Subscriber<Stream<E>> windowTime(Duration duration) {
    if (duration == null) throw ArgumentError.notNull('duration');

    return window(Stream<void>.periodic(duration));
  }

  /// Creates an Subscriber that emits when the source stream emits, combining
  /// the latest values from the two streams using the provided function.
  ///
  /// If the latestFromStream has not emitted any values, this stream will not
  /// emit either.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#withLatestFrom)
  ///
  /// ### Example
  ///
  ///     new Subscriber.fromIterable([1, 2]).withLatestFrom(
  ///       new Subscriber.fromIterable([2, 3]), (a, b) => a + b)
  ///       .listen(print); // prints 4 (due to the async nature of streams)
  @override
  Subscriber<R> withLatestFrom<S, R>(
          Stream<S> latestFromStream, R fn(E t, S s)) =>
      transform(WithLatestFromStreamTransformer<E, S, R>(latestFromStream, fn));

  /// Returns an Subscriber that combines the current stream together with
  /// another stream using a given zipper function.
  ///
  /// ### Example
  ///
  ///     new Subscriber.just(1)
  ///         .zipWith(new Subscriber.just(2), (one, two) => one + two)
  ///         .listen(print); // prints 3
  @override
  Subscriber<R> zipWith<S, R>(Stream<S> other, R zipper(E t, S s)) =>
      Subscriber<R>.fromStream(
          ZipStream.zip2(controller.stream, other, zipper));

  /// Convert the current Subscriber into a [ConnectableSubscriber]
  /// that can be listened to multiple times. It will not begin emitting items
  /// from the original Subscriber until the `connect` method is invoked.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream.
  ///
  /// ### Example
  ///
  /// ```
  /// final source = Subscriber.fromIterable([1, 2, 3]);
  /// final connectable = source.publish();
  ///
  /// // Does not print anything at first
  /// connectable.listen(print);
  ///
  /// // Start listening to the source Subscriber. Will cause the previous
  /// // line to start printing 1, 2, 3
  /// final subscription = connectable.connect();
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // Subject
  /// subscription.cancel();
  /// ```
  @override
  ConnectableObservable<E> publish() => PublishConnectableObservable<E>(this);

  /// Convert the current Subscriber into a [ValueConnectableSubscriber]
  /// that can be listened to multiple times. It will not begin emitting items
  /// from the original Subscriber until the `connect` method is invoked.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream that replays the latest emitted value to any new
  /// listener. It also provides access to the latest value synchronously.
  ///
  /// ### Example
  ///
  /// ```
  /// final source = Subscriber.fromIterable([1, 2, 3]);
  /// final connectable = source.publishValue();
  ///
  /// // Does not print anything at first
  /// connectable.listen(print);
  ///
  /// // Start listening to the source Subscriber. Will cause the previous
  /// // line to start printing 1, 2, 3
  /// final subscription = connectable.connect();
  ///
  /// // Late subscribers will receive the last emitted value
  /// connectable.listen(print); // Prints 3
  ///
  /// // Can access the latest emitted value synchronously. Prints 3
  /// print(connectable.value);
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // BehaviorSubject
  /// subscription.cancel();
  /// ```
  @override
  ValueConnectableObservable<E> publishValue() =>
      ValueConnectableObservable<E>(this);

  /// Convert the current Subscriber into a [ValueConnectableSubscriber]
  /// that can be listened to multiple times, providing an initial seeded value.
  /// It will not begin emitting items from the original Subscriber
  /// until the `connect` method is invoked.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream that replays the latest emitted value to any new
  /// listener. It also provides access to the latest value synchronously.
  ///
  /// ### Example
  ///
  /// ```
  /// final source = Subscriber.fromIterable([1, 2, 3]);
  /// final connectable = source.publishValueSeeded(0);
  ///
  /// // Does not print anything at first
  /// connectable.listen(print);
  ///
  /// // Start listening to the source Subscriber. Will cause the previous
  /// // line to start printing 0, 1, 2, 3
  /// final subscription = connectable.connect();
  ///
  /// // Late subscribers will receive the last emitted value
  /// connectable.listen(print); // Prints 3
  ///
  /// // Can access the latest emitted value synchronously. Prints 3
  /// print(connectable.value);
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // BehaviorSubject
  /// subscription.cancel();
  /// ```
  @override
  ValueConnectableObservable<E> publishValueSeeded(E seedValue) =>
      ValueConnectableObservable<E>.seeded(this, seedValue);

  /// Convert the current Subscriber into a [ReplayConnectableSubscriber]
  /// that can be listened to multiple times. It will not begin emitting items
  /// from the original Subscriber until the `connect` method is invoked.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream that replays a given number of items to any new
  /// listener. It also provides access to the emitted values synchronously.
  ///
  /// ### Example
  ///
  /// ```
  /// final source = Subscriber.fromIterable([1, 2, 3]);
  /// final connectable = source.publishReplay();
  ///
  /// // Does not print anything at first
  /// connectable.listen(print);
  ///
  /// // Start listening to the source Subscriber. Will cause the previous
  /// // line to start printing 1, 2, 3
  /// final subscription = connectable.connect();
  ///
  /// // Late subscribers will receive the emitted value, up to a specified
  /// // maxSize
  /// connectable.listen(print); // Prints 1, 2, 3
  ///
  /// // Can access a list of the emitted values synchronously. Prints [1, 2, 3]
  /// print(connectable.values);
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // ReplaySubject
  /// subscription.cancel();
  /// ```
  @override
  ReplayConnectableObservable<E> publishReplay({int maxSize}) =>
      ReplayConnectableObservable<E>(this, maxSize: maxSize);

  /// Convert the current Subscriber into a new Subscriber that can be listened
  /// to multiple times. It will automatically begin emitting items when first
  /// listened to, and shut down when no listeners remain.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream.
  ///
  /// ### Example
  ///
  /// ```
  /// // Convert a single-subscription fromIterable stream into a broadcast
  /// // stream
  /// final observable = Subscriber.fromIterable([1, 2, 3]).share();
  ///
  /// // Start listening to the source Subscriber. Will start printing 1, 2, 3
  /// final subscription = observable.listen(print);
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // PublishSubject
  /// subscription.cancel();
  /// ```
  @override
  Subscriber<E> share() => publish().refCount();

  /// Convert the current Subscriber into a new [ValueSubscriber] that can
  /// be listened to multiple times. It will automatically begin emitting items
  /// when first listened to, and shut down when no listeners remain.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream. It's also useful for providing sync access to the latest
  /// emitted value.
  ///
  /// It will replay the latest emitted value to any new listener.
  ///
  /// ### Example
  ///
  /// ```
  /// // Convert a single-subscription fromIterable stream into a broadcast
  /// // stream that will emit the latest value to any new listeners
  /// final observable = Subscriber.fromIterable([1, 2, 3]).shareValue();
  ///
  /// // Start listening to the source Subscriber. Will start printing 1, 2, 3
  /// final subscription = observable.listen(print);
  ///
  /// // Synchronously print the latest value
  /// print(observable.value);
  ///
  /// // Subscribe again later. This will print 3 because it receives the last
  /// // emitted value.
  /// final subscription2 = observable.listen(print);
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // BehaviorSubject by cancelling all subscriptions.
  /// subscription.cancel();
  /// subscription2.cancel();
  /// ```
  @override
  ValueObservable<E> shareValue() => publishValue().refCount();

  /// Convert the current Subscriber into a new [ValueSubscriber] that can
  /// be listened to multiple times, providing an initial value.
  /// It will automatically begin emitting items when first listened to,
  /// and shut down when no listeners remain.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream. It's also useful for providing sync access to the latest
  /// emitted value.
  ///
  /// It will replay the latest emitted value to any new listener.
  ///
  /// ### Example
  ///
  /// ```
  /// // Convert a single-subscription fromIterable stream into a broadcast
  /// // stream that will emit the latest value to any new listeners
  /// final observable = Subscriber.fromIterable([1, 2, 3]).shareValueSeeded(0);
  ///
  /// // Start listening to the source Subscriber. Will start printing 0, 1, 2, 3
  /// final subscription = observable.listen(print);
  ///
  /// // Synchronously print the latest value
  /// print(observable.value);
  ///
  /// // Subscribe again later. This will print 3 because it receives the last
  /// // emitted value.
  /// final subscription2 = observable.listen(print);
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // BehaviorSubject by cancelling all subscriptions.
  /// subscription.cancel();
  /// subscription2.cancel();
  /// ```
  @override
  ValueObservable<E> shareValueSeeded(E seedValue) =>
      publishValueSeeded(seedValue).refCount();

  /// Convert the current Subscriber into a new [ReplaySubscriber] that can
  /// be listened to multiple times. It will automatically begin emitting items
  /// when first listened to, and shut down when no listeners remain.
  ///
  /// This is useful for converting a single-subscription stream into a
  /// broadcast Stream. It's also useful for gaining access to the l
  ///
  /// It will replay the emitted values to any new listener, up to a given
  /// [maxSize].
  ///
  /// ### Example
  ///
  /// ```
  /// // Convert a single-subscription fromIterable stream into a broadcast
  /// // stream that will emit the latest value to any new listeners
  /// final observable = Subscriber.fromIterable([1, 2, 3]).shareReplay();
  ///
  /// // Start listening to the source Subscriber. Will start printing 1, 2, 3
  /// final subscription = observable.listen(print);
  ///
  /// // Synchronously print the emitted values up to a given maxSize
  /// // Prints [1, 2, 3]
  /// print(observable.values);
  ///
  /// // Subscribe again later. This will print 1, 2, 3 because it receives the
  /// // last emitted value.
  /// final subscription2 = observable.listen(print);
  ///
  /// // Stop emitting items from the source stream and close the underlying
  /// // ReplaySubject by cancelling all subscriptions.
  /// subscription.cancel();
  /// subscription2.cancel();
  /// ```
  @override
  ReplayObservable<E> shareReplay({int maxSize}) =>
      publishReplay(maxSize: maxSize).refCount();
}
