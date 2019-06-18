import 'dart:async';

import 'package:meta/meta.dart';
import 'package:nbtb/nbtb.dart';
import 'package:nbtb/src/event_subscriber.dart';

abstract class Bloc {
  @mustCallSuper
  void dispose() => null;
}

abstract class SingleIOBloc<EInput, EOutput> extends Bloc {
  final EventSubscriber<EInput> subscriber;
  final EventEmitter<EOutput> emitter;

  SingleIOBloc()
    : subscriber = EventSubscriber<EInput>(),
      emitter = EventEmitter<EOutput>() {
    subscriber.listen(onInput);
  }

  void onInput(EInput data);

  void emit(EOutput data) {
    emitter.emit(data);
  }

  @override
  @mustCallSuper
  void dispose() {
    subscriber.close();
    emitter.close();
    super.dispose();
  }
}