import 'package:nbtb/nbtb.dart';

void main() {
  final emitterA = BlocEmitterA();
  final emitterB = BlocEmitterB();

  final foo = BlocBar(bar);
  final foo2 = BlocBar(bar);
  final foo3 = BlocBaz(bar);
  final foo4 = BlocBar(bar);

  bar.emitValue(5);
}

class BlocEmitterA extends Bloc {
  EventEmitter<int> emitter = EventEmitter();

  void emitValue(int value) {
    emitter.emit(value);
  }
}


class BlocEmitterB extends Bloc {
  EventEmitter<int> emitter = EventEmitter();

  BlocEmitterB() {
    emitter.transform(transformer);
  }

  int transformer(int data) => data * 2;

  void emitValue(int value) {
    emitter.emit(value);
  }
}

class BlocB extends Bloc {
  EventSubscriber<int> subscriber;

  BlocBar(BlocA bar) {
    subscriber = EventSubscriber(onEvent);
    subscriber.subscribeTo(bar.emitter);
  }

  void onEvent(int data) {
    print(data);
  }
}

class BlocC extends Bloc {
  EventSubscriber<int> subscriber;

  BlocBaz(BlocA bar) {
    subscriber = EventSubscriber(
        onEvent,
        transformer: EventTransformer.fromHandler(transformer),
    );
    subscriber.subscribeTo(bar.emitter);
  }

  void onEvent(int data) {
    print(data);
  }

  int transformer(int data) => data * 2;
}

class BlocD extends Bloc {
  EventSubscriber<int> subscriber;

  BlocBaz(BlocA bar) {
    subscriber = EventSubscriber(
      onEvent,
      transformer: EventTransformer.fromHandler(transformer),
    );
    subscriber.subscribeTo(bar.emitter);
  }

  void onEvent(int data) {
    print(data);
  }

  int transformer(int data) => data * 2;
}