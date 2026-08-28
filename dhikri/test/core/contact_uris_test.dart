import 'package:dhikri/core/constants/developer_contact.dart';
import 'package:dhikri/core/services/contact_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('رقم المطوّر', () {
    test('رقم واتساب هو 967774354548 بلا علامة زائد', () {
      expect(DeveloperContact.whatsAppNumber, '967774354548');
      expect(DeveloperContact.whatsAppNumber.contains('+'), isFalse);
    });

    test('رقم الهاتف بصيغة دولية كاملة', () {
      expect(DeveloperContact.phoneE164, '+967774354548');
    });

    test('الرقمان متطابقان عدا علامة الزائد', () {
      expect(
        DeveloperContact.phoneE164.replaceFirst('+', ''),
        DeveloperContact.whatsAppNumber,
      );
    });
  });

  group('ContactUris', () {
    test('رابط الاتصال يستخدم tel والرقم الصحيح', () {
      final uri = ContactUris.call();
      expect(uri.scheme, 'tel');
      expect(uri.path, '+967774354548');
      expect(uri.toString(), 'tel:+967774354548');
    });

    test('رابط الرسائل يستخدم sms ويحمل نص الرسالة مرمَّزًا', () {
      final uri = ContactUris.sms(ContactUris.smsMessage());
      expect(uri.scheme, 'sms');
      expect(uri.path, '+967774354548');
      expect(uri.query, startsWith('body='));
      // المسافات تُرمَّز %20 وليس + حتى لا تظهر علامة زائد في نص الرسالة.
      expect(uri.query.contains('+'), isFalse);
      expect(uri.queryParameters['body'], contains('تطبيق ذكري'));
    });

    test('رابط واتساب العام يستخدم wa.me والرقم بلا زائد', () {
      final uri = ContactUris.whatsAppWeb('مرحبا');
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/967774354548');
      expect(uri.queryParameters['text'], 'مرحبا');
    });

    test('رابط تطبيق واتساب يحمل الرقم والنص', () {
      final uri = ContactUris.whatsAppApp('مرحبا');
      expect(uri.scheme, 'whatsapp');
      expect(uri.host, 'send');
      expect(uri.queryParameters['phone'], '967774354548');
      expect(uri.queryParameters['text'], 'مرحبا');
    });

    test('نص واتساب يحتوي النسخة والنظام بلا معرّفات جهاز', () {
      final message = ContactUris.whatsAppMessage(
        version: '1.0.0 (1)',
        platform: 'Android',
      );
      expect(message, contains('السلام عليكم'));
      expect(message, contains('تطبيق ذكري'));
      expect(message, contains('1.0.0 (1)'));
      expect(message, contains('Android'));
      expect(message, isNot(contains('IMEI')));
    });

    test('نص واتساب يعمل بدون ذكر النظام', () {
      final message = ContactUris.whatsAppMessage(version: '1.0.0');
      expect(message, isNot(contains('النظام:')));
    });
  });
}
