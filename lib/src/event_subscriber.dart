import 'dart:async';

import 'package:meta/meta.dart';
import 'package:nbtb/src/event.dart';
import 'package:nbtb/src/event_emitter.dart';
import 'package:nbtb/src/event_route_node.dart';
import 'package:nbtb/src/event_transformer.dart';
import 'package:nbtb/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

class EventSubscriber<E> extends EventRouteNode<E> implements StreamConsumer<E> {
  final BehaviorSubject<E> subject;

  EventTransformer transformer;

  EventSubscriber({
    OnStreamEvent<E> onEvent,
    OnStreamError onError,
    OnStreamDone onDone,
  }) : subject = BehaviorSubject<E>() {
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
  }) : subject = BehaviorSubject<E>.seeded(initialValue) {
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
  }) : subject = BehaviorSubject<E>() {
    assert (onEvent != null || (onError == null && onDone == null));
    subject.addStream(stream);
    if (onEvent != null) {
      listen(onEvent, onError: onError, onDone: onDone);
    }
  }

  @override
  EventSubscriber<T> transform<T>(EventTransformer<E, T> transformer) {
    transformer.source = this;
    transformer.destination = EventSubscriber<T>.withStream(
      this.subject.transform<T>(
        StreamTransformer.fromHandlers(handleData: (data, sink) {
          sink.add(transformer.transform(data));
        }),
      ),
    );

    this.transformer = transformer;
    return transformer.destination;
  }

  @override
  StreamSubscription<E> listen(onEvent, {onError, onDone}) {
    return subject.listen(onEvent, onError: onError, onDone: onDone);
  }

  @override
  Future addStream(Stream<E> stream) async {
    await subject.addStream(stream);
  }

  @override
  Future close() async {
    await subject.close();
  }
}