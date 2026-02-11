import 'constants.dart';

/// File delivery rules: mp4 200MB, mp3 50MB, pdf 20MB. Unlock only after "Ready for Delivery".
class FileRules {
  static const String extMp4 = 'mp4';
  static const String extMp3 = 'mp3';
  static const String extPdf = 'pdf';

  static int maxBytesForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case extMp4:
        return AppConstants.maxFileSizeBytesMp4;
      case extMp3:
        return AppConstants.maxFileSizeBytesMp3;
      case extPdf:
        return AppConstants.maxFileSizeBytesPdf;
      default:
        return 0;
    }
  }

  static bool isAllowedExtension(String ext) {
    return AppConstants.allowedDeliveryExtensions.contains(ext.toLowerCase());
  }

  static String get allowedExtensionsDisplay => AppConstants.allowedDeliveryExtensions.join(', ').toUpperCase();
}
