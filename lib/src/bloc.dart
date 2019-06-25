import 'package:meta/meta.dart';
import 'package:nothin_but_the_bloc/nothin_but_the_bloc.dart';
import 'package:nothin_but_the_bloc/src/subscriber.dart';

/// The base class for all BLoC structures.
abstract class Bloc {
  void dispose() => null;
}

/// A utility BLoC structure that comes pre-populated with a single
/// [Subscriber] input stream and a single [Emitter] output stream of
/// types `EInput` and `EOutput`, respectively. Disposal of the streams is also
/// handled automatically.
abstract class SingleIOBloc<EInput, EOutput> extends Bloc {
  final Subscriber<EInput> subscriber;
  final Emitter<EOutput> emitter;

  SingleIOBloc() : this.withControllers();

  SingleIOBloc.withControllers({
    Subscriber<EInput> subscriber,
    Emitter<EOutput> emitter,
  })  : this.subscriber = subscriber ?? Subscriber<EInput>(),
        this.emitter = emitter ?? Emitter<EOutput>() {
    this.subscriber.listen(onInput);
  }

  /// Override this method to handle incoming events from [subscriber], the
  /// input stream.
  void onInput(EInput data) => null;

  /// Call this method to publish events to [emitter], the output stream.
  void emit(EOutput data) {
    emitter.emit(data);
  }

  @override
  @mustCallSuper
  void dispose() async {
    await emitter.close();
    await subscriber.close();
  }
}
