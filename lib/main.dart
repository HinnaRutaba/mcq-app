import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection.dart';

void main() {
  // Before `setupDependencies`, not left to `runApp`: building the dependency
  // graph reaches a platform channel — `ConnectivityInterceptor` subscribes to
  // the connectivity stream in its constructor — and a channel needs
  // `ServicesBinding.instance` to already exist.
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const McqApp());
}
