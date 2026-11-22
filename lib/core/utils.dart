import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, User;
import 'package:url_launcher/url_launcher.dart';

class AppConstants {
  static const storeName = 'متجري';
  static const currency = 'ج.م';

  /// رقم واتساب الخاص بك بالصيغة الدولية بدون + (مثال لمصر: 201012345678)
  static const whatsappNumber = '201000000000';
}

const Map<String, String> orderStatuses = {
  'pending': 'قيد المراجعة',
  'confirmed': 'تم التأكيد',
  'shipped': 'تم الشحن',
  'delivered': 'تم التسليم',
  'cancelled': 'ملغي',
};

String formatPrice(num v) {
  final s = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
  return '$s ${AppConstants.currency}';
}

String formatDate(DateTime? d) {
  if (d == null) return '';
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

/// يحول رقم مصري محلي (01xxxxxxxxx) إلى الصيغة الدولية (201xxxxxxxxx)
String normalizePhone(String raw) {
  var p = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (p.startsWith('00')) p = p.substring(2);
  if (p.startsWith('0')) p = '20${p.substring(1)}';
  return p;
}

Future<void> openWhatsApp(String message, {String? phone}) async {
  final number =
      phone == null ? AppConstants.whatsappNumber : normalizePhone(phone);
  final uri =
      Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> callPhone(String phone) async {
  await launchUrl(Uri(scheme: 'tel', path: phone));
}

String userNameOf(User? u) => (u?.userMetadata?['name'] ?? '') as String;

String authErrorMessage(AuthException e) {
  final m = e.message.toLowerCase();
  if (m.contains('invalid login') || m.contains('invalid credentials')) {
    return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
  }
  if (m.contains('already registered') || m.contains('already been registered')) {
    return 'هذا البريد مسجل بالفعل';
  }
  if (m.contains('password') && (m.contains('least') || m.contains('weak'))) {
    return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
  }
  if (m.contains('email not confirmed')) {
    return 'يجب تأكيد بريدك الإلكتروني أولاً (راجع رسالة التأكيد)';
  }
  if (m.contains('invalid') && m.contains('email')) {
    return 'البريد الإلكتروني غير صحيح';
  }
  if (m.contains('rate limit') || m.contains('too many')) {
    return 'محاولات كثيرة، حاول لاحقاً';
  }
  return 'حدث خطأ: ${e.message}';
}
