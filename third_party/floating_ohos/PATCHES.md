# floating snapshot

Source snapshot of upstream `floating` 6.0.0 (https://github.com/wrbl606/floating).
`media_core_pip` needs an Android system picture-in-picture backend, and the
upstream Android Gradle script still applies the standalone Kotlin Gradle
Plugin, which fails against AGP 9 built-in Kotlin with
`Cannot add extension with name 'kotlin'`.

## Build changes

- drop `kotlin-android` and the KGP classpath; AGP provides Kotlin compilation
  and the standard library;
- Java 17 bytecode target;
- Flutter floor raised to 3.44, the built-in Kotlin migration boundary.

## Behaviour changes

These are not build edits. `FloatingSystemPip` maps `pipStatusStream`, so the
host sees the polled status, not just the immediate reply:

- probe interval 100 ms instead of 10 ms;
- polling is owned by listeners (broadcast `onListen`/`onCancel`) rather than a
  `Timer.periodic` that never stops;
- one request in flight, the next probe is scheduled after the previous reply;
- replies from a retired observation are discarded;
- a failed query keeps the last known status and logs once per failure stretch;
- geometry of the active PiP window is refreshed.

`test/floating_status_lifecycle_test.dart` pins these through method-channel
fixtures.

## Removal

When an upstream release builds under built-in Kotlin, move `media_core_pip`
back to the hosted version only after porting the behaviour changes above, then
delete this package and its workspace entry.
