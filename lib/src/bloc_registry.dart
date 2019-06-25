import 'package:nothin_but_the_bloc/src/bloc.dart';

/// A singleton-based registry to hold global references to [Bloc] objects.
class BlocRegistry {
  static final _inst = BlocRegistry._();
  BlocRegistry._();

  final _blocs = <Type, Bloc>{};

  /// Registers a [Bloc] using its subclass type as a key. If a bloc is already
  /// registered under that type, `replaceIfExists` can be set to `true` to
  /// overwrite the previous value, otherwise this method will do nothing.
  ///
  /// The returned `bool` represents if a bloc was registered under the
  /// specified type before this method was called.
  static bool register<T extends Bloc>(T bloc, {bool replaceIfExists = false})
    => _inst._register(bloc, replaceIfExists: replaceIfExists);

  bool _register<T extends Bloc>(T bloc, {bool replaceIfExists = false}) {
    final exists = _blocs.containsKey(T);
    if (!exists || replaceIfExists) {
      _blocs[T] = bloc;
    }
    return exists;
  }

  /// Returns a [Bloc] stored under the key specified by the type `T`. If no bloc
  /// exists under that type, this method returns `null`.
  static T get<T extends Bloc>() => _inst._get<T>();

  T _get<T extends Bloc>() {
    return _blocs[T];
  }
}