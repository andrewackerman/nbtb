import 'dart:async';

import 'package:nbtb/src/event_subscriber.dart';
import 'package:nbtb/src/typedefs.dart';

class EventEmitter<E> {
  final StreamController<E> controller;

  EventEmitter()
      : controller = StreamController<E>.broadcast();

  EventEmitter.withStream(Stream<E> stream)
      : controller = StreamController<E>.broadcast() {
    ArgumentError.checkNotNull(stream);
    controller.addStream(stream);
  }

  void emit(E event) {
    controller.add(event);
  }

  EventSubscriber<E> createSubscription({
      OnStreamEvent<E> onEvent,
      OnStreamError onError,
      OnStreamDone onDone,
    }) {
    return EventSubscriber<E>(onEvent: onEvent, onError: onError, onDone: onDone)
      ..controller.addStream(this.controller.stream);
  }

  void close() {
    controller.close();
  }
}