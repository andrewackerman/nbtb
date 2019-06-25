typedef OnStreamEvent<E> = void Function(E data);
typedef OnStreamError = void Function(Object error, StackTrace stackTrace);
typedef OnStreamDone = void Function();
