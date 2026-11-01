# SQLite HarmonyOS build

Dart API: unchanged pub.dev sqlite3 3.8.0 (locked upstream dependency).
OHOS hook compiles the previously validated SQLite 3.53.4 public-domain amalgamation with the real OpenHarmony compiler/sysroot; other hosts keep the original hook. Source archive: https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip, recorded SHA256 1e71ddf93849c6a6ecf58b827c0692073d2dd7ee40196158068f7b29f422e87d. Source copied from the earlier HarmonyOS adaptation, not a Linux binary. Database/backup tests must run on the new binding before delivery.
