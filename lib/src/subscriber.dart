import 'dart:async';

import 'package:nothin_but_the_bloc/src/emitter.dart';
import 'package:nothin_but_the_bloc/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

/// A [BehaviorSubject]-based class that is designed to be an input stream.
/// Subscribers can register an [Emitter] to listen to their updates.
class Subscriber<E> extends Subject<E> implements ValueObservable<E> {
  _Wrapper<E> _wrapper;

  Subscriber._(
    StreamController<E> controller,
    Observable<E> observable,
    this._wrapper,
  ) : super(controller, observable);

  factory Subscriber._fromStream(Stream<E> stream) {
    final controller = StreamController<E>.broadcast();
    controller.addStream(stream);

    final wrapper = _Wrapper<E>();
    return Subscriber._(controller, Observable<E>(controller.stream), wrapper);
  }

  /// Creates a [Subscriber] with an empty item queue.
  ///
  /// The `onEvent` callback will be triggered when the subscriber receives an event.
  ///
  /// The `onError` callback will be triggered when the subscriber receives an error.
  ///
  /// The `onDone` callback will be triggered when the subscriber closes.
  factory Subscriber({
    OnStreamEvent<E> onEvent,
    OnStreamError onError,
    OnStreamDone onDone,
  }) {
    final controller = StreamController<E>.broadcast();
    final wrapper = _Wrapper<E>();
    final subscriber = Subscriber<E>._(
      controller,
      Observable<E>.defer(() {
        if (wrapper.latestIsError) {
          scheduleMicrotask(() {
            controller.addError(wrapper.latestError, wrapper.latestStackTrace);
          });
        } else if (wrapper.latestIsValue) {
          return Observable<E>(controller.stream)
            .startWith(wrapper.latestValue);
        }

        return controller.stream;
      }),
      wrapper,
    );

    subscriber.listen(onEvent, onError: onError, onDone: onDone);

    return subscriber;
  }

  /// Creates a [Subscriber] with an item queue seeded by the given [seedValue].
  ///
  /// The `onEvent` callback will be triggered when the subscriber receives an event.
  ///
  /// The `onError` callback will be triggered when the subscriber receives an error.
  ///
  /// The `onDone` callback will be triggered when the subscriber closes.
  factory Subscriber.seeded(
    E seedValue, {
    OnStreamEvent<E> onEvent,
    OnStreamError onError,
    OnStreamDone onDone,
    void Function() onListen,
    void Function() onCancel,
    bool sync = false,
  }) {
    final controller = StreamController<E>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper = _Wrapper<E>.seeded(seedValue);

    final subscriber = Subscriber<E>._(
      controller,
      Observable<E>.defer(() {
        if (wrapper.latestIsError) {
          scheduleMicrotask(() {
            controller.addError(wrapper.latestError, wrapper.latestStackTrace);
          });
        }

        return Observable<E>(controller.stream).startWith(wrapper.latestValue);
      }),
      wrapper,
    );

    if (onEvent != null) {
      subscriber.listen(onEvent, onError: onError, onDone: onDone);
    }

    return subscriber;
  }

  @override
  void onAdd(E event) => _wrapper.setValue(event);

  @override
  void onAddError(Object error, [StackTrace stackTrace]) =>
    _wrapper.setError(error, stackTrace);

  @override
  ValueObservable<E> get stream => this;

  /// Get if the stream currently has a value.
  @override
  bool get hasValue => _wrapper.latestIsValue;

  /// Get the latest value received by the subscriber.
  @override
  E get value => _wrapper.latestValue;

  /// Set and emit the new value.
//  set value(E newValue) => add(newValue);

  /// Utility method for listening to multiple streams at once.
  void addStreams(Iterable<Stream<E>> streams) async {
    for (var stream in streams) {
      await addStream(stream);
    }
  }

  /// Registers an emitter with this subscriber, listening to its events.
  void addEmitter(Emitter<E> emitter) async
    => await addStream(emitter.controller.stream);

  /// Utility method for listening to multiple emitters at once.
  void addEmitters(Iterable<Emitter<E>> emitters) async {
    for (var emitter in emitters) {
      await addStream(emitter.controller.stream);
    }
  }

  @override
  Subscriber<T> transform<T>(StreamTransformer<E, T> streamTransformer) {
    return Subscriber<T>._fromStream(streamTransformer.bind(controller.stream));
  }

  /// Utility method for transforming this stream with a handler that returns a
  /// transformed [Observable]. Returns a new [Subscriber] that listens to the
  /// transformed [Observable] for events.
  Subscriber<T> transformWithHandler<T>(Observable<T> Function(Observable<E> source) transformer) {
    return Subscriber<T>()..addStream(
      transformer(Observable<E>(controller.stream)),
    );
  }

  /// Creates an Observable where each item is a List containing the items from the source sequence. (See [Observable.buffer] for more details.)
  Subscriber<List<E>> buffer(Stream window)
    => transformWithHandler<List<E>>((source) => source.buffer(window));

  /// Buffers a number of values from the source Observable by count then emits the buffer and clears it, and starts a new buffer each startBufferEvery values. If startBufferEvery is not provided, then new buffers are started immediately at the start of the source and when each buffer closes and is emitted.
  Subscriber<List<E>> bufferCount(int count, [int startBufferEvery = 0])
    => transformWithHandler<List<E>>((source) => source.bufferCount(count, startBufferEvery));

  /// Creates an Observable where each item is a List containing the items from the source sequence, batched whenever test passes.
  Subscriber<List<E>> bufferTest(bool onTestHandler(E event))
    => transformWithHandler<List<E>>((source) => source.bufferTest(onTestHandler));

  /// Creates an Observable where each item is a List containing the items from the source sequence, sampled on a time frame with duration.
  Subscriber<List<E>> bufferTime(Duration duration)
    => transformWithHandler<List<E>>((source) => source.bufferTime(duration));

  /// Adapt this stream to be a Stream<T>.
  Subscriber<T> cast<T>()
    => transformWithHandler<T>((source) => source.cast<T>());

  /// Transforms a Stream so that will only emit items from the source sequence if a window has completed, without the source sequence emitting another item.
  Subscriber<E> debounce(Stream Function(E event) window)
    => transformWithHandler<E>((source) => source.debounce(window));

  /// Transforms a Stream so that will only emit items from the source sequence whenever the time span defined by duration passes, without the source sequence emitting another item.
  Subscriber<E> debounceTime(Duration duration)
    => transformWithHandler<E>((source) => source.debounceTime(duration));

  /// The Delay operator modifies its source Observable by pausing for a particular increment of time (that you specify) before emitting each of the source Observable’s items. This has the effect of shifting the entire sequence of items emitted by the Observable forward in time by that specified increment.
  Subscriber<E> delay(Duration duration)
    => transformWithHandler<E>((source) => source.delay(duration));

  /// Creates an Observable where data events are skipped if they are equal to the previous data event.
  Subscriber<E> distinct([bool Function(E e1, E e2) equals])
    => transformWithHandler<E>((source) => source.distinct(equals));

  /// Creates an Observable from this stream that converts each element into zero or more events.
  Subscriber<T> expand<T>(Iterable<T> Function(E value) convert)
    => transformWithHandler<T>((source) => source.expand<T>(convert));

  /// Creates an Observable that emits each item in the Stream after a given duration.
  Subscriber<E> interval(Duration duration)
    => transformWithHandler<E>((source) => source.interval(duration));

  /// Maps values from a source sequence through a function and emits the returned values.
  Subscriber<T> map<T>(T Function(E event) handler)
    => transformWithHandler<T>((source) => source.map<T>(handler));

  /// Emits the given constant value on the output Observable every time the source Observable emits a value.
  Subscriber<T> mapTo<T>(T value)
    => transformWithHandler<T>((source) => source.mapTo<T>(value));

  /// Skips the first count data events from this stream.
  Subscriber<E> skip(int count)
    => transformWithHandler<E>((source) => source.skip(count));

  /// Starts emitting items only after the given stream emits an item.
  Subscriber<E> skipUntil<T>(Stream<T> otherStream)
    => transformWithHandler<E>((source) => source.skipUntil(otherStream));

  /// Skip data events from this stream while they are matched by test.
  Subscriber<E> skipWhile(bool Function(E data) condition)
    => transformWithHandler<E>((source) => source.skipWhile(condition));

  /// Prepends a value to the source Observable.
  Subscriber<E> startWith(E element)
    => transformWithHandler<E>((source) => source.startWith(element));

  /// Prepends a sequence of values to the source Observable.
  Subscriber<E> startWithMany(List<E> element)
    => transformWithHandler<E>((source) => source.startWithMany(element));

  /// Provides at most the first n values of this stream. Forwards the first n data events of this stream, and all error events, to the returned stream, and ends with a done event.
  Subscriber<E> take(int count)
    => transformWithHandler<E>((source) => source.take(count));

  /// Returns the values from the source observable sequence until the other observable sequence produces a value.
  Subscriber<E> takeUntil<T>(Stream<T> otherStream)
    => transformWithHandler<E>((source) => source.takeUntil(otherStream));

  /// Forwards data events while test is successful.
  Subscriber<E> takeWhile(bool Function(E data) condition)
    => transformWithHandler<E>((source) => source.takeWhile(condition));

  /// Emits only the first item emitted by the source Stream while window is open.
  Subscriber<E> throttle(Stream Function(E event) window, {bool trailing = false})
    => transformWithHandler<E>((source) => source.throttle(window, trailing: trailing));

  /// Emits only the first item emitted by the source Stream within a time span of duration.
  Subscriber<E> throttleTime(Duration duration, {bool trailing = false})
    => transformWithHandler<E>((source) => source.throttleTime(duration, trailing: trailing));

  /// Records the time interval between consecutive values in an observable sequence.
  Subscriber<TimeInterval<E>> timeInterval()
    => transformWithHandler<TimeInterval<E>>((source) => source.timeInterval());

  /// The Timeout operator allows you to abort an Observable with an onError termination if that Observable fails to emit any items during a specified duration. You may optionally provide a callback function to execute on timeout.
  Subscriber<E> timeout(Duration timeLimit, {void onTimeout(EventSink<E> sink)})
    => transformWithHandler<E>((source) => source.timeout(timeLimit, onTimeout: onTimeout));

  /// Wraps each item emitted by the source Observable in a Timestamped object that includes the emitted item and the time when the item was emitted.
  Subscriber<Timestamped<E>> timestamp()
    => transformWithHandler<Timestamped<E>>((source) => source.timestamp());

  /// Filters the elements of an observable sequence based on the test.
  Subscriber<E> where(bool Function(E data) condition)
    => transformWithHandler<E>((source) => source.where(condition));

  /// Creates an Observable where each item is a Stream containing the items from the source sequence.
  Subscriber<Stream<E>> window(Stream window)
    => transformWithHandler<Stream<E>>((source) => source.window(window));

  /// Buffers a number of values from the source Observable by count then emits the buffer as a Stream and clears it, and starts a new buffer each startBufferEvery values. If startBufferEvery is not provided, then new buffers are started immediately at the start of the source and when each buffer closes and is emitted.
  Subscriber<Stream<E>> windowCount(int count, [int startBufferEvery = 0])
    => transformWithHandler<Stream<E>>((source) => source.windowCount(count, startBufferEvery));

  /// Creates an Observable where each item is a Stream containing the items from the source sequence, batched whenever test passes.
  Subscriber<Stream<E>> windowTest(bool onTestHandler(E event))
    => transformWithHandler<Stream<E>>((source) => source.windowTest(onTestHandler));

  /// Creates an Observable where each item is a Stream containing the items from the source sequence, sampled on a time frame with duration.
  Subscriber<Stream<E>> windowTime(Duration duration)
    => transformWithHandler<Stream<E>>((source) => source.windowTime(duration));

  /// Returns an Observable that combines the current stream together with another stream using a given zipper function.
  Subscriber<U> zipWith<T, U>(Stream<T> other, U zipper(E e, T t))
    => transformWithHandler<U>((source) => source.zipWith(other, zipper));
}

class _Wrapper<T> {
  T latestValue;
  Object latestError;
  StackTrace latestStackTrace;

  bool latestIsValue = false, latestIsError = false;

  /// Non-seeded constructor
  _Wrapper();

  _Wrapper.seeded(this.latestValue) : latestIsValue = true;

  void setValue(T event) {
    latestIsValue = true;
    latestIsError = false;

    latestValue = event;

    latestError = null;
    latestStackTrace = null;
  }

  void setError(Object error, [StackTrace stackTrace]) {
    latestIsValue = false;
    latestIsError = true;

    latestValue = null;

    latestError = error;
    latestStackTrace = stackTrace;
  }
}