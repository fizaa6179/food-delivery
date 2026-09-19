import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Card entry used on the checkout screen.
///
/// Android / iOS: Stripe's native [CardFormField], exactly as before.
/// Web: flutter_stripe has no card-field widget for web (only the Payment
/// Element), so a plain Flutter form is used instead. Card payment in this
/// app is simulated, so nothing is sent anywhere - this only collects input
/// and reports whether it looks complete.
class CardInputField extends StatelessWidget {
  final ValueChanged<bool> onCompleteChanged;

  const CardInputField({super.key, required this.onCompleteChanged});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _WebCardForm(onCompleteChanged: onCompleteChanged);
    }

    return CardFormField(
      style: CardFormStyle(
        borderColor: Colors.grey.shade200,
        textColor: Colors.black87,
        placeholderColor: Colors.grey,
      ),
      onCardChanged: (details) => onCompleteChanged(details?.complete ?? false),
    );
  }
}

class _WebCardForm extends StatefulWidget {
  final ValueChanged<bool> onCompleteChanged;

  const _WebCardForm({required this.onCompleteChanged});

  @override
  State<_WebCardForm> createState() => _WebCardFormState();
}

class _WebCardFormState extends State<_WebCardForm> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  bool _lastComplete = false;

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    _cvc.dispose();
    super.dispose();
  }

  bool get _isComplete {
    final digits = _number.text.replaceAll(' ', '');
    if (digits.length < 13 || digits.length > 19) return false;

    final parts = _expiry.text.split('/');
    if (parts.length != 2 || parts[1].length != 2) return false;
    final month = int.tryParse(parts[0]);
    if (month == null || month < 1 || month > 12) return false;

    return _cvc.text.length >= 3;
  }

  void _notify() {
    final complete = _isComplete;
    if (complete != _lastComplete) {
      _lastComplete = complete;
      widget.onCompleteChanged(complete);
    }
  }

  InputDecoration _decoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = Colors.grey.shade200;

    return Column(
      children: [
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [_CardNumberFormatter()],
          onChanged: (_) => _notify(),
          decoration: _decoration('Card number', icon: Icons.credit_card_rounded),
        ),
        Divider(height: 1, color: divider),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiry,
                keyboardType: TextInputType.number,
                inputFormatters: [_ExpiryFormatter()],
                onChanged: (_) => _notify(),
                decoration: _decoration('MM/YY'),
              ),
            ),
            SizedBox(height: 28, child: VerticalDivider(width: 1, color: divider)),
            Expanded(
              child: TextField(
                controller: _cvc,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (_) => _notify(),
                decoration: _decoration('CVC'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Digits only, max 19, grouped as "1234 5678 9012 3456".
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 19) digits = digits.substring(0, 19);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Digits only, max 4, shown as "MM/YY".
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    final text = digits.length > 2 ? '${digits.substring(0, 2)}/${digits.substring(2)}' : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
