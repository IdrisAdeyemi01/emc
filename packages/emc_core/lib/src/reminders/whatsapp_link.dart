import 'phone_number.dart';

/// Click-to-chat link that opens WhatsApp in [phone]'s chat with [message]
/// prefilled. The admin still taps Send herself (no automation).
Uri whatsAppLink(ValidPhone phone, String message) => Uri.parse(
  'https://wa.me/${phone.digits}?text=${Uri.encodeComponent(message)}',
);
