import 'dart:async';

import 'package:nbtb/src/event_transformer.dart';
import 'package:nbtb/src/typedefs.dart';

abstract class EventRouteNode<E> {
  StreamSubscription<E> listen(
    OnStreamEvent<E> onEvent, {
    OnStreamError onError,
    OnStreamDone onDone,
  });

  EventRouteNode<T> transform<T>(EventTransformer<E, T> transformer);

  EventRouteNode<T> map<T>(T Function(E event) handler)
    => transform(EventTransformer.map(handler));
  EventRouteNode<E> skip(int count)
    => transform(EventTransformer.skip(count));
  EventRouteNode<E> skipWhile(bool Function(E data) condition)
    => transform(EventTransformer.skipWhile(condition));
  EventRouteNode<E> take(int count)
    => transform(EventTransformer.take(count));
  EventRouteNode<E> takeWhile(bool Function(E data) condition)
    => transform(EventTransformer.takeWhile(condition));
  EventRouteNode<E> where(bool Function(E data) condition)
    => transform(EventTransformer.where(condition));
}