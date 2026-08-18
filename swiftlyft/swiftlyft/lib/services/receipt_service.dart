import 'package:intl/intl.dart';
import '../models/booking.dart';

class ReceiptService {
  static String generateReceiptText(Booking booking) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final b = booking;
    final lines = <String>[
      'SwiftLyft Receipt',
      '=================',
      'Booking ID: ${b.id}',
      'Date: ${df.format(b.pickupTime)}',
      'Vehicle: ${b.vehicleName}',
      'Driver: ${b.driverName}',
      'Passengers: ${b.passengerCount}',
      '',
      'From: ${b.pickupAddress}',
      'To  : ${b.dropoffAddress}',
      '',
      'Charges:',
      '  Base Price: R${b.basePrice.toStringAsFixed(2)}',
      if (b.closeProtectionOfficer) '  Close Protection: R500.00',
      '  Total: R${b.finalPrice.toStringAsFixed(2)}',
      '',
      'Payment Status: ${b.paymentStatusText}',
    ];
    return lines.join('\n');
  }

  static String generateInvoiceText(Booking booking) {
    final df = DateFormat('yyyy-MM-dd');
    final due = booking.pickupTime.add(const Duration(days: 7));
    final lines = <String>[
      'SwiftLyft Tax Invoice',
      '======================',
      'Invoice #: INV-${booking.id}',
      'Invoice Date: ${df.format(DateTime.now())}',
      'Due Date: ${df.format(due)}',
      '',
      'Bill To:',
      '  ${booking.userId}',
      '',
      'Description:',
      '  ${booking.vehicleName} trip from ${booking.pickupAddress} to ${booking.dropoffAddress}',
      '',
      'Amount Due: R${booking.finalPrice.toStringAsFixed(2)}',
      '',
      'Thank you for riding with SwiftLyft!',
    ];
    return lines.join('\n');
  }
}


