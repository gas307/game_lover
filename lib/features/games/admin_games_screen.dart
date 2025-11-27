import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminGamesScreen extends StatelessWidget {
  const AdminGamesScreen({super.key});
  static const routeName = '/admin-games';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('nav.admin_panel'.tr()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Admin panel is disabled in the RAWG-based version of the app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
