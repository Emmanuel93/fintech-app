enum NotificationType {
  movement,
  paymentDue,
  paymentReceived,
  transferOut,
  transferIn,
  statement,
  security,
  withdrawal,
  benefit,
  marketing,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
    this.actionRoute,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;
  final String? actionRoute;
}
