import 'package:nbtb/nbtb.dart';

void main() {
  final emitterA = BlocEmitterA();
  final emitterB = BlocEmitterB();

  final subscriberA = BlocSubscriberA(emitterA);
  final subscriberB = BlocSubscriberB(emitterA);
  final subscriberC = BlocSubscriberC(emitterB);
  final subscriberD = BlocSubscriberD(emitterA, emitterB);

  emitterA.emitValue(5);
  emitterB.emitValue('abcd');
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
                         .transformWithHandler(transformer)
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
                                 .transformWithHandler(transformer)
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
    subscriberB = emitterB.emitter.createSubscription(onEvent: onEventB);
  }

  void onEventA(int data) {
    print('SubscriberD recieved event from EmitterA: $data');
  }

  void onEventB(String data) {
    print('SubscriberD recieved event from EmitterB: $data');
  }
}