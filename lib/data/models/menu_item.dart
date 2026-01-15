// lib/models/screen_models.dart

/// Menu Items for the Drawer/Nav.
class MenuItem {
  final String title;
  final String route;
  final dynamic icon; // IconData usually

  MenuItem(this.title, this.route, this.icon);
}
