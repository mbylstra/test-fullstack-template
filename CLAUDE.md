# Flutter Project Rules

## Flutter/Dart Development

- ALWAYS run `make flutter-analyze` after making any code changes
- Never manually edit pubspec.yaml to add dependencies
- Always use `dart pub add` or `flutter pub add` to install packages

### Code Reuse and DRY Principle

- BEFORE duplicating any code block, ALWAYS ask if we should extract/reuse existing code instead
- When you notice similar code patterns, proactively suggest refactoring
- Search the codebase first before creating new implementations
- Prefer refactoring over copy-paste, even if it takes more steps
- If duplicating code, explicitly state WHY duplication is appropriate in this case

### Import Style

- Never use basic wildcard imports - they make it impossible to know where variables come from when reading code
- Prefer `show` when the meaning of the import is clear without the package (either because it is self explanatory or because it is a very commonly used variable such as a Flutter widget).Eg: `firestore_auth.FirestoreAuth` is not more readable than just `FirestoreAuth`. `Card` is preferable to `material.Card` because it is so commonly used in UI screens.
- Prefer prefixed imports (`as`) when it gives clarity to the name. Eg: `firestore.Timestamp` is clearer than just `Timestamp`
