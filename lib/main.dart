import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection.dart';

Future<void> main() async {
  // Storage and the keychain are read before the first frame, so the
  // session check can start the moment the launch screen appears.
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const McqApp());
}
