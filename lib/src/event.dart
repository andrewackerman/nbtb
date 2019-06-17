import "package:meta/meta.dart";

@immutable
class Event<T> {
  const Event();
  static Event fromValue<T>(T value) => _ValueEvent<T>(value);
}

class _ValueEvent<T> extends Event<T> {
  final T value;
  const _ValueEvent(this.value);
}