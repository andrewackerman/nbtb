import 'dart:async';

import 'package:nbtb/src/event.dart';
import 'package:nbtb/src/event_emitter.dart';
import 'package:nbtb/src/event_transformer.dart';
import 'package:nbtb/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

class EventSubscriber<E> implements StreamConsumer<E> {
  final BehaviorSubject<E> subject;
  final IEventTransformer<E> transformer;

  OnStreamEvent<E> onEvent;
  OnStreamError onError;
  OnStreamDone onDone;

  EventSubscriber(
    this.onEvent, {
      this.transformer,
      this.onError,
      this.onDone,
    }) : subject = BehaviorSubject<E>() {
    subject.listen(onEvent, onError: onError, onDone: onDone);
  }

  EventSubscriber.seeded(
    E initialValue,
    this.onEvent, {
      this.transformer,
      this.onError,
      this.onDone,
    }) : subject = BehaviorSubject<E>.seeded(initialValue) {
    subject.listen(onEvent, onError: onError, onDone: onDone);
  }

  void subscribeTo(EventEmitter emitter) {
    emitter.createSubscription(this, transformer);
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