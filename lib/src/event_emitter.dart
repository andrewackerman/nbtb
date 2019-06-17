import 'dart:async';

import 'package:nbtb/src/event.dart';
import 'package:nbtb/src/event_route_node.dart';
import 'package:nbtb/src/event_route_node.dart';
import 'package:nbtb/src/event_subscriber.dart';
import 'package:nbtb/src/event_transformer.dart';
import 'package:nbtb/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

class EventEmitter<E> {
  final PublishSubject<E> subject;
  final bool closeOnError;

  EventTransformer transformer;

  EventEmitter({this.closeOnError = false})
      : subject = PublishSubject<E>();

  EventEmitter.withStream(Stream<E> stream, {this.closeOnError = false})
      : subject = PublishSubject<E>() {
    ArgumentError.checkNotNull(stream);
    subject.addStream(stream);
  }

  void emit(E event) {
    subject.add(event);
  }

  EventSubscriber<E> createSubscription({
      OnStreamEvent<E> onEvent,
      OnStreamError onError,
      OnStreamDone onDone,
    }) {
    return EventSubscriber<E>(onEvent: onEvent, onError: onError, onDone: onDone)
      ..subject.addStream(this.subject);
  }
}