# Walkthrough: Change default Ollama model to qwen3:4b in env

## Task
Change the default Ollama model from the previous value to `qwen3:4b` so that local Ollama-backed AI calls fall back to the new default when no `OLLAMA_MODEL` is set.

## Classification
TINY — single-line config default change across two files; no new behavior, tests, or architecture.

## Files Modified

### 1. `.env.example`
Updated the documented `OLLAMA_MODEL` default from the generic placeholder to the concrete value `qwen3:4b`:

```diff
- OLLAMA_MODEL=your_ollama_model_here
+ OLLAMA_MODEL=qwen3:4b
```

This serves as the example/contract for any developer copying the file to `.env`.

### 2. `lib/core/services/ai/ai_provider.dart`
Updated the `ollamaModelProvider` fallback default in both the `try` and `catch` branches of the env lookup, so the in-code default matches the documented `.env` default:

```diff
 final ollamaModelProvider = Provider<String>((ref) {
   try {
-    return dotenv.env['OLLAMA_MODEL'] ?? 'gemma2:2b';
+    return dotenv.env['OLLAMA_MODEL'] ?? 'qwen3:4b';
   } catch (_) {
-    return 'gemma2:2b';
+    return 'qwen3:4b';
   }
 });
```

This ensures the app picks `qwen3:4b` when:
- `OLLAMA_MODEL` is unset in `.env`, or
- `flutter_dotenv` throws (e.g., during tests or when `.env` is missing entirely).

## Verification

### `flutter analyze`
42 issues found — all pre-existing deprecations (`withOpacity`, `surfaceVariant`, `anonKey`) and pre-existing unnecessary `!` warnings. **No new issues** were introduced by this change. No errors.

### `flutter test`
All 42 tests passed:

- 1 widget test
- 6 offline pronunciation analyzer tests
- 5 mock AI provider tests
- 9 accent coach view-model tests
- 21 supporting test cases

## Notes
- No production behavior changes for users who already set `OLLAMA_MODEL` explicitly in their local `.env` — their value is still respected.
- The change brings the in-code default into alignment with the documented `.env.example` value, so a fresh clone will get `qwen3:4b` out of the box for local Ollama runs.
- No new dependencies, no new files in `lib/` or `test/`, no architectural impact.
