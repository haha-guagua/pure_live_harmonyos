# HarmonyOS UI platform cases

Source: official Flutter cupertino_ui 1.1.4, unchanged version and BSD license retained. 17 switch patterns explicitly include TargetPlatform.ohos alongside the touch UI behavior used on Android. The runtime remains OHOS: no native Android plugin or Platform.isAndroid override is enabled. This is required after Flutter split Material/Cupertino into separately published libraries whose platform switches do not yet handle OHOS. Application widget regressions run on the OHOS target variant.
