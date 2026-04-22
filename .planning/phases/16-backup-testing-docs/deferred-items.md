# Phase 16 - Deferred Items

## Pre-existing Analyze Issues (Out of Scope)

1. **cost_config_provider_test.dart** - 16 argument_type_not_assignable errors + 1 unused_local_variable warning. Drift `Value<T>` wrapper mismatch in test assertions. Pre-existing from Phase 13.
2. **rooms_screen_test.dart:8** - unused_import of smart_plug_dao.dart. Pre-existing from Phase 15.
3. **tool/parse_coverage.dart** - 8 avoid_print info messages. Intentional CLI tool usage.
