import 'dart:async';

import 'package:meta/meta.dart';
import 'package:nbtb/src/event_subscriber.dart';
import 'package:nbtb/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

abstract class IEventEmitter<E> {
  StreamController<E> get controller;

  EventSubscriber<E> createSubscription({
    OnStreamEvent<E> onEvent,
    OnStreamError onError,
    OnStreamDone onDone,
  }) {
    return EventSubscriber<E>(onEvent: onEvent, onError: onError, onDone: onDone)
      ..controller.addStream(this.controller.stream);
  }

  void emit(E event) {
    controller.add(event);
  }

  @mustCallSuper
  void close() {
    controller.close();
  }
}

class EventEmitter<E> extends IEventEmitter<E> {
  final PublishSubject<E> controller;

  EventEmitter()
      : controller = PublishSubject<E>();

  EventEmitter.withStream(Stream<E> stream)
      : controller = PublishSubject<E>() {
    ArgumentError.checkNotNull(stream);
    controller.addStream(stream);
  }
}