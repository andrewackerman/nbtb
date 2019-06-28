## [0.0.3]

- Renamed `addEmitter` and `addEmitters` method in `Subscriber` to `listenToEmitter` and `listenToEmitters`.
- Added `fromStream` and `just` factory constructors to `Subscriber`.
- Created base abstract class `BlocSubject` that `Emitter` and `Subscriber` now extend.
- All transformation methods exposed by `Subject` and `StreamController` that return an `Observer` have been reimplemented to return a `Subscriber` to facilitate a unified usage experience.

## [0.0.2]

- Removed dependency on pedantic to eliminate a case of failed dependency resolution. Copied the linter rules from version 1.7.0 to maintain analyzer behavior.

## [0.0.1]

- Initial version
- Documentation is slap-dashed together. It will be expanded and cleaned up in the future.
