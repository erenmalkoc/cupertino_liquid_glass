# Contributing to this Project

First off, thank you for considering contributing! It's people like you that make the open-source community such an amazing place to learn, inspire, and create.

## How Can I Contribute?

### Reporting Bugs
* Check the **Issues** tab to see if the bug has already been reported.
* If not, open a new issue. Use a clear title and provide as much context as possible (Flutter version, device info, steps to reproduce).

### Suggesting Enhancements
* Open an issue with the tag `enhancement`.
* Explain why this feature would be useful and how it should work.

### Pull Requests
1. **Fork** the repository.
2. **Create a branch** for your feature or fix.
3. **Commit your changes**.
4. **Run tests** to ensure everything is working.
5. **Push to the branch** .
6. **Open a Pull Request**.

## Style Guide
* Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
* Use `dart format .` before committing.
* Ensure `flutter analyze --fatal-infos` passes without any errors, warnings or infos.

### Local checks
CI runs the same gate on every push and pull request, so run it before opening a PR:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
(cd example && flutter test)
dart pub publish --dry-run
```

CI also analyzes and tests the package on the minimum supported Flutter (3.32.8), so avoid language features or APIs newer than Dart 3.8 / Flutter 3.32 in `lib/` and `test/`.

## Code of Conduct
Please be respectful and professional in all interactions. 