
class EventTransformer<ESource, EDest> {
  final Stream<EDest> Function(Stream<ESource> data) transformer;

  EventTransformer.fromHandler(this.transformer);

  static EventTransformer<ESource, EDest> map<ESource, EDest>(EDest Function(ESource data) mapFunc) {
    return EventTransformer<ESource, EDest>.fromHandler((source) => source.map(mapFunc));
  }

  static EventTransformer<ESource, ESource> skip<ESource>(int count) {
    return EventTransformer<ESource, ESource>.fromHandler((source) => source.skip(count));
  }

  static EventTransformer<ESource, ESource> skipWhile<ESource>(bool Function(ESource element) condition) {
    return EventTransformer.fromHandler((source) => source.skipWhile(condition));
  }

  static EventTransformer<ESource, ESource> take<ESource>(int count) {
    return EventTransformer<ESource, ESource>.fromHandler((source) => source.take(count));
  }

  static EventTransformer<ESource, ESource> takeWhile<ESource>(bool Function(ESource element) condition) {
    return EventTransformer.fromHandler((source) => source.takeWhile(condition));
  }

  static EventTransformer<ESource, ESource> where<ESource>(bool Function(ESource element) condition) {
    return EventTransformer.fromHandler((source) => source.where(condition));
  }

  Stream<EDest> transform(Stream<ESource> data) {
    return transformer(data);
  }
}