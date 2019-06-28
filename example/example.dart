import 'package:nothin_but_the_bloc/nothin_but_the_bloc.dart';

void main() async {
  final emitterA = BlocEmitterA();

  final emitterB = BlocEmitterB();
  BlocRegistry.register(emitterB);

  final subscriberA = BlocSubscriberA(emitterA);
  final subscriberB = BlocSubscriberB(emitterA);
  final subscriberC = BlocSubscriberC();
  final subscriberD = BlocSubscriberD(emitterA);

  final ioBloc = IOBloc(emitterA.emitter);
  final ioBlocListener = IOBlocListener(ioBloc.emitter);

  await emitterA.emitValue(5);
  await emitterB.emitValue('a');
  await emitterB.emitValue('b');
  await emitterB.emitValue('c');
  await emitterB.emitValue('d');

  emitterA.dispose();
  emitterB.dispose();
  ioBloc.dispose();

  subscriberA.dispose();
  subscriberB.dispose();
  subscriberC.dispose();
  subscriberD.dispose();
  ioBlocListener.dispose();
}

class BlocEmitterA extends Bloc {
  Emitter<int> emitter = Emitter();

  void emitValue(int data) {
    print('EmitterA is broadcasting an event: $data');
    emitter.emit(data);
  }

  void dispose() {
    emitter.close();
  }
}

class BlocEmitterB extends Bloc {
  Emitter<String> emitter;

  BlocEmitterB() {
    emitter = Emitter<String>();
  }

  String transformer(int data) => 's${data.toString()}';

  void emitValue(String data) {
    print('EmitterB is broadcasting an event: $data');
    emitter.emit(data);
  }

  void dispose() {
    emitter.close();
  }
}

class BlocSubscriberA extends Bloc {
  Subscriber<int> subscriber;

  BlocSubscriberA(BlocEmitterA emitterA) {
    subscriber = emitterA.emitter.createSubscriber(onEvent: onEvent);
  }

  void onEvent(int data) {
    print('SubscriberA recieved event from EmitterA: $data');
  }
}

class BlocSubscriberB extends Bloc {
  Subscriber<String> subscriber;

  BlocSubscriberB(BlocEmitterA emitterA) {
    subscriber = emitterA.emitter.createSubscriber().map(transformer)
      ..listen(onEvent);
  }

  String transformer(int data) => 's${data.toString()}';

  void onEvent(String data) {
    print('SubscriberB recieved event from EmitterA: $data');
  }

  void dispose() {
    subscriber.close();
  }
}

class BlocSubscriberC extends Bloc {
  Subscriber<int> subscriber;

  BlocSubscriberC() {
    subscriber = BlocRegistry.get<BlocEmitterB>()
        .emitter
        .createSubscriber()
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

  void dispose() {
    subscriber.close();
  }
}

class BlocSubscriberD extends Bloc {
  Subscriber<int> subscriberA;
  Subscriber<String> subscriberB;

  BlocSubscriberD(BlocEmitterA emitterA) {
    subscriberA = emitterA.emitter.createSubscriber(onEvent: onEventA);
    subscriberB = BlocRegistry.get<BlocEmitterB>()
        .emitter
        .createSubscriber()
        .skip(2)
          ..listen(onEventB);
  }

  void onEventA(int data) {
    print('SubscriberD recieved event from EmitterA: $data');
  }

  void onEventB(String data) {
    print('SubscriberD recieved event from EmitterB: $data');
  }

  void dispose() {
    subscriberA.close();
    subscriberB.close();
  }
}

class IOBloc extends SingleIOBloc<int, String> {
  IOBloc(Emitter<int> emitterA) {
    subscriber.listenToEmitter(emitterA);
  }

  @override
  void onInput(int data) {
    print('IOBloc recieved an event: $data');
    emit('IO' + data.toString());
  }
}

class IOBlocListener extends SingleIOBloc<String, Null> {
  IOBlocListener(Emitter<String> ioBloc) {
    subscriber.listenToEmitter(ioBloc);
  }

  @override
  void onInput(String data) {
    print('IOBlocListener recieved an event: $data');
  }
}
