import 'dart:async';

import 'package:nbtb/src/event.dart';
import 'package:nbtb/src/event_subscriber.dart';
import 'package:nbtb/src/event_transformer.dart';
import 'package:nbtb/src/typedefs.dart';
import 'package:rxdart/rxdart.dart';

class EventEmitter<E> {
  final PublishSubject<E> subject;
  final bool closeOnError;

  EventEmitter({this.closeOnError = false})
    : subject = PublishSubject<E>();

  void emit(E event) {
    subject.add(event);
  }

  createSubscription(EventSubscriber<E> subscriber, [IEventTransformer<E> transformer]) {
    Observable<E> subj = subject;
    if (transformer != null) {
      subj = subj.transform(
        StreamTransformer.fromHandlers(handleData: (data, sink) {
          sink.add(transformer.transform(data));
        }),
      );
    }
    return subj.pipe(subscriber);
  }
}