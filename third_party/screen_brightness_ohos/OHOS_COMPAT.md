# HarmonyOS compatibility sources

Source: screen_brightness_ohos 2.1.4 from pub.dev, upstream https://github.com/aaassseee/screen_brightness.
Archive SHA-256: `569a2c97909a50894b81487619eb7654f5358443a5af05f840c19261f49c0940`. Original license retained.

Local changes: correct system-event handler registration, obtain the active Ability context explicitly, await window brightness writes/reset before acknowledging completion. Uses application window brightness only; does not write system settings.
