/// Short Portuguese description of how long ago something happened.
String relativeTime(DateTime moment, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(moment);
  if (difference.inMinutes < 1) return 'agora';
  if (difference.inMinutes < 60) return 'há ${difference.inMinutes} min';
  if (difference.inHours < 24) return 'há ${difference.inHours} h';
  if (difference.inDays == 1) return 'ontem';
  if (difference.inDays < 30) return 'há ${difference.inDays} dias';
  final local = moment.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return 'em $day/$month/${local.year}';
}
