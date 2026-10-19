# Material compatibility for Flutter OH 3.41

This application-only adapter exports the Material API still bundled with
Flutter 3.41. It keeps the app and dynamic_color 2.x on the same ColorScheme,
ThemeData and Material widget types. It is not a general replacement for all
APIs in the independent material_ui 1.x library. Theme and color-picker behavior
must be validated in this branch before a HAP is accepted.
