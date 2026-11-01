# Windows native build output

Source: pub.dev native_toolchain_c 0.19.5; BSD license retained. No compiler checks are skipped. The process runner decodes explicitly requested `-utf8` output (notably vswhere JSON) as UTF-8 instead of the Windows active code page, and uses incremental decoders to retain split multibyte characters. This fixes actual C++ host compilation on Chinese Windows; OpenHarmony compiler resolution remains unchanged. Regression: tools/harmonyos/test/native_toolchain_output_test.dart.
