import 'package:flutter/material.dart';
import 'router/app_router.dart';

class SMNApp extends StatelessWidget {
  const SMNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SMN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
