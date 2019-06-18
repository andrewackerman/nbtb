import 'package:nbtb/nbtb.dart';

void main() {
  final emitterA = BlocEmitterA();
  final emitterB = BlocEmitterB();

  final subscriberA = BlocSubscriberA(emitterA);
  final subscriberB = BlocSubscriberB(emitterA);
  final subscriberC = BlocSubscriberC(emitterB);
  final subscriberD = BlocSubscriberD(emitterA, emitterB);

  final ioBloc = IOBloc(emitterA.emitter);
  final ioBlocListener = IOBlocListener(ioBloc.emitter);

  emitterA.emitValue(5);
  emitterB.emitValue('a');
  emitterB.emitValue('b');
  emitterB.emitValue('c');
  emitterB.emitValue('d');
}

class BlocEmitterA extends Bloc {
  EventEmitter<int> emitter = EventEmitter();

  void emitValue(int data) {
    print('EmitterA is broadcasting an event: $data');
    emitter.emit(data);
  }
}


class BlocEmitterB extends Bloc {
  EventEmitter<String> emitter;

  BlocEmitterB() {
    emitter = EventEmitter<String>();
  }

  String transformer(int data) => 's${data.toString()}';

  void emitValue(String data) {
    print('EmitterB is broadcasting an event: $data');
    emitter.emit(data);
  }
}

class BlocSubscriberA extends Bloc {
  EventSubscriber<int> subscriber;

  BlocSubscriberA(BlocEmitterA emitterA) {
    subscriber = emitterA.emitter.createSubscription(onEvent: onEvent);
  }

  void onEvent(int data) {
    print('SubscriberA recieved event from EmitterA: $data');
  }
}

class BlocSubscriberB extends Bloc {
  EventSubscriber<String> subscriber;

  BlocSubscriberB(BlocEmitterA emitterA) {
    subscriber = emitterA.emitter
                         .createSubscription()
                         .map(transformer)
                         ..listen(onEvent);
  }

  String transformer(int data) => 's${data.toString()}';

  void onEvent(String data) {
    print('SubscriberB recieved event from EmitterA: $data');
  }
}

class BlocSubscriberC extends Bloc {
  EventSubscriber<int> subscriber;

  BlocSubscriberC(BlocEmitterB emitterB) {
    subscriber = emitterB.emitter.createSubscription()
                                 .map(transformer)
                                 ..listen(onEvent);
  }

  int transformer(String data) {
    int total = 0;
    for (var code in data.codeUnits) {
      total += code;
    }
    return total;
  }

  void onEvent(int data) {
    print('SubscriberC recieved event from EmitterB: $data');
  }
}

class BlocSubscriberD extends Bloc {
  EventSubscriber<int> subscriberA;
  EventSubscriber<String> subscriberB;

  BlocSubscriberD(BlocEmitterA emitterA, BlocEmitterB emitterB) {
    subscriberA = emitterA.emitter.createSubscription(onEvent: onEventA);
    subscriberB = emitterB.emitter.createSubscription()
                                  .skip(2)
                                  ..listen(onEventB);
  }

  void onEventA(int data) {
    print('SubscriberD recieved event from EmitterA: $data');
  }

  void onEventB(String data) {
    print('SubscriberD recieved event from EmitterB: $data');
  }
}

class IOBloc extends SingleIOBloc<int, String> {
  IOBloc(EventEmitter<int> emitterA) {
    subscriber.addEmitter(emitterA);
  }

  @override
  void onInput(int data) {
    print('IOBloc recieved an event: $data');
    emit('IO' + data.toString());
  }
}

class IOBlocListener extends SingleIOBloc<String, Null> {
  IOBlocListener(EventEmitter<String> ioBloc) {
    subscriber.addEmitter(ioBloc);
  }

  @override
  void onInput(String data) {
    print('IOBlocListener recieved an event: $data');
  }
}