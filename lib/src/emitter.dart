import 'dart:async';

import 'package:nothin_but_the_bloc/src/bloc_subject.dart';
import 'package:nothin_but_the_bloc/src/subscriber.dart';
import 'package:nothin_but_the_bloc/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

/// A [PublishSubject]-based class that is designed to be an output stream.
/// Emitters can be registered by [Subscriber] streams to listen to their updates.
class Emitter<E> extends BlocSubject<E> {
  Emitter._(StreamController<E> controller, Observable<E> observable)
      : super(controller, observable);

  /// Creates an [Emitter] with an empty item queue.
  ///
  /// The ``onListen` callback will be triggered when a new listener is added
  /// to the stream.
  ///
  /// The `onCancel` callback will be triggered when the stream is canceled. This
  /// can happen when all listeners have cancelled their subscriptions and there
  /// are no more active listeners.
  ///
  /// If `sync` is true, events can be fired synchronously during calls to
  /// `emit` or `emitError`. Doing so must be done with care so as to not break
  /// the [Stream] contract.
  ///
  /// If `sync` is false, events will be fired asynchronously. No guarantees are
  /// made as to when listeners will receive the events except that they will
  /// receive them in the correct order. If multiple listeners are sent events,
  /// no guarantees are made as to which listener will receive events first, or
  /// how many events one listener will receive before another receives any.
  factory Emitter({
    void Function() onListen,
    void Function() onCancel,
    bool sync = false,
  }) {
    final controller = StreamController<E>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    return Emitter._(controller, Observable<E>(controller.stream));
  }

  /// Emits an event to any listeners.
  void emit(E event) {
    add(event);
  }

  /// Emits an error object and description to listeners.
  void emitError(Object error, StackTrace st) {
    addError(error, st);
  }

  /// Creates a [Subscriber] object of this emitter's type that is preconfigured
  /// to listen to this emitter's events.
  ///
  /// The `onEvent` callback will trigger whenever this emitter emits an event.
  ///
  /// The `onError` callback will trigger whenever this emitter emits an error.
  ///
  /// The `onDone` callback will trigger when the subscriber closes.
  Subscriber<E> createSubscriber({
    OnStreamEvent<E> onEvent,
    OnStreamError onError,
    OnStreamDone onDone,
  }) {
    final subscriber = Subscriber<E>.fromStream(controller.stream);
    subscriber.listen(
      onEvent,
      onError: onError,
      onDone: onDone,
    );
    return subscriber;
  }
}
