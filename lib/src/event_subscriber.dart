import 'dart:async';

import 'package:meta/meta.dart';
import 'package:nbtb/src/event_emitter.dart';
import 'package:nbtb/src/event_route_node.dart';
import 'package:nbtb/src/event_transformer.dart';
import 'package:nbtb/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

abstract class IEventSubscriber<E> extends EventRouteNode<E> {
  StreamController<E> get controller;

  void addEmitter(EventEmitter<E> emitter) {
    controller.addStream(emitter.controller.stream);
  }

  StreamSubscription<E> listen(onEvent, {onError, onDone}) {
    return controller.stream.listen(onEvent, onError: onError, onDone: onDone);
  }

  @mustCallSuper
  void close() {
    controller.close();
  }
}

class EventSubscriber<E> extends IEventSubscriber<E> {
  final BehaviorSubject<E> controller;

  EventTransformer transformer;

  EventSubscriber({
    OnStreamEvent<E> onEvent,
    OnStreamError onError,
    OnStreamDone onDone,
  }) : controller = BehaviorSubject<E>() {
    assert (onEvent != null || (onError == null && onDone == null));
    if (onEvent != null) {
      listen(onEvent, onError: onError, onDone: onDone);
    }
  }

  EventSubscriber.seeded(
    E initialValue, {
      OnStreamEvent<E> onEvent,
      OnStreamError onError,
      OnStreamDone onDone,
  }) : controller = BehaviorSubject<E>.seeded(initialValue) {
    assert (onEvent != null || (onError == null && onDone == null));
    if (onEvent != null) {
      listen(onEvent, onError: onError, onDone: onDone);
    }
  }

  EventSubscriber.withStream(
    Stream stream, {
      OnStreamEvent<E> onEvent,
      OnStreamError onError,
      OnStreamDone onDone,
  }) : this.controller = BehaviorSubject<E>() {
    assert (onEvent != null || (onError == null && onDone == null));
    this.controller.addStream(stream);
    if (onEvent != null) {
      listen(onEvent, onError: onError, onDone: onDone);
    }
  }

  @override
  EventSubscriber<T> transform<T>(EventTransformer<E, T> transformer) {
    return EventSubscriber<T>.withStream(
      transformer.transform(this.controller.stream),
    );
  }


}