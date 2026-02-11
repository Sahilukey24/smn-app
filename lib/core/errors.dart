/// App-level errors.
class AppException implements Exception {
  AppException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

class CartCreatorMismatchException extends AppException {
  CartCreatorMismatchException()
      : super('Cart can only contain services from one creator. Clear cart or add from the same creator.');
}

class DeadlineExceedsMaxException extends AppException {
  DeadlineExceedsMaxException(int maxDays)
      : super('Deadline cannot be more than $maxDays days from today.');
}

class CounterProposalsExceededException extends AppException {
  CounterProposalsExceededException()
      : super('Maximum counter proposals reached.');
}

class FileTooLargeException extends AppException {
  FileTooLargeException(int maxMb)
      : super('File size must be under ${maxMb}MB.');
}

class DeliveryNotReadyException extends AppException {
  DeliveryNotReadyException()
      : super('Creator must mark "Ready for Delivery" before you can upload.');
}

class InvalidFileTypeException extends AppException {
  InvalidFileTypeException()
      : super('Only MP4, MP3, and PDF are allowed for delivery.');
}
