import 'dart:async';

import 'package:nothin_but_the_bloc/src/bloc_subject.dart';
import 'package:nothin_but_the_bloc/src/emitter.dart';
import 'package:nothin_but_the_bloc/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

/// A [BehaviorSubject]-based class that is designed to be an input stream, though
/// it can also be listened to and treated as an output stream. Subscribers can
/// register an [Emitter] to listen to their updates.
class Subscriber<E> extends BlocSubject<E> implements ValueObservable<E> {
  _Wrapper<E> _wrapper;

  Subscriber._(
    StreamController<E> controller,
    Observable<E> observable,
    this._wrapper,
  ) : super(controller, observable);

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

  /// Creates an Observable that contains a single value
  ///
  /// The value is emitted when the stream receives a listener.
  factory Subscriber.just(E data) =>
      Subscriber.fromStream(Stream<E>.fromIterable(<E>[data]));

  /// Creates a Subscriber that is configured to listen to events from a
  /// source stream.
  factory Subscriber.fromStream(Stream<E> source) {
    final subscriber = Subscriber<E>();
    source.pipe(subscriber);
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
  close() async {
    await controller.stream.drain();
    await super.close();
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

  /// Registers an emitter with this subscriber, listening to its events.
  void listenToEmitter(Emitter<E> emitter) async =>
      await emitter.controller.stream.pipe(this);

  /// Utility method for listening to multiple emitters at once.
  void listenToEmitters(Iterable<Emitter<E>> emitters) async {
    for (var emitter in emitters) {
      await emitter.controller.stream.pipe(this);
    }
  }

  @override
  Subscriber<T> transform<T>(StreamTransformer<E, T> streamTransformer) {
    final subscriber = Subscriber<T>();
    streamTransformer.bind(controller.stream).pipe(subscriber);
    return subscriber;
  }

  /// Utility method for transforming this stream with a handler that returns a
  /// transformed [Observable]. Returns a new [Subscriber] that listens to the
  /// transformed [Observable] for events.
  Subscriber<T> transformWithHandler<T>(
      Observable<T> Function(Observable<E> source) transformer) {
    final subscriber = Subscriber<T>();
    transformer(Observable<E>(controller.stream)).pipe(subscriber);
    return subscriber;
  }
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
