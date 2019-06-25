A library that aims to make BLoC principles more intuitive to implement.

## Usage

A simple usage example:

```dart
import 'package:nothin_but_the_bloc/nothin_but_the_bloc.dart';
   
class BlocEmitter extends Bloc {
  Emitter<int> emitter = Emitter();

  void emitValue(int data) {
    print('BlocEmitter is broadcasting an event: $data');
    emitter.emit(data);
  }

  void dispose() {
    emitter.close();
  }
}

class BlocSubscriber extends Bloc {
  Subscriber<int> subscriber;

  BlocSubscriberA(BlocEmitter bloc) {
    subscriber = bloc.emitter.createSubscriber(onEvent: onEvent);
  }

  void onEvent(int data) {
    print('BlocSubscriber received event from BlocEmitter: $data');
  }
}

void main() {
  final blocEmitter = BlocEmitter();
  final blocSubscriber = BlocSubscriber(blocEmitter);
  
  emitter.emitValue(5);
  
  // Printed:
  // BlocEmitter is broadcasting an event: 5
  // BlocSubscriber received event from BlocEmitter: 5
  
  blocSubscriber.dispose();
  blocEmitter.dispose();
}
```

For a more extended example, see the [example project](https://github.com/andrewackerman/nbnt/blob/master/example/example.dart).

## TODO
 
- Make more comprehensive documentation
- Override `StreamController` and `Subject` inherited methods in `Emitter` and `Subscriber` to return an `Emitter`/`Subscriber` (so they can be properly chained)
