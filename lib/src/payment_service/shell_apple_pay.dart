import 'shell_pay.dart';
import 'package:pay/pay.dart';

class ShellApplePay {
  ShellPay? _shellPay;
  final PaymentConfiguration _config;
  static const PayProvider _payProvider = PayProvider.apple_pay;

  ShellApplePay(this._config) {
    _shellPay = ShellPay({_payProvider : _config});
  }

  Future<bool> userCanPay() async {
    return _shellPay!.userCanPay(_payProvider);
  }

  Future<Map<String, dynamic>> pay(List<PaymentItem> paymentItems) async {
    final result = await _shellPay!.showPaymentSelector(_payProvider, paymentItems);

    return result;
  }
}