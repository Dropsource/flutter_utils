import 'package:intl/intl.dart';

extension StringFormatting on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + substring(1);
  }
}

String? formatPhoneNumber(String? phoneNumber) {
  if (phoneNumber == null) {
    return '';
  }
  const digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  final numbersOnly = phoneNumber.split('').where(digits.contains).join('');
  final length = numbersOnly.length;
  final hasLeadingOne = numbersOnly[0] == '1';
  if (length == 7 || length == 10 || (length == 11 && hasLeadingOne)) {
    final hasAreaCode = (length >= 10);
    var sourceIndex = 0;

    // Leading 1
    var leadingOne = '';
    if (hasLeadingOne) {
      leadingOne = '1 ';
      sourceIndex += 1;
    }

    // Area code
    var areaCode = '';
    if (hasAreaCode) {
      const areaCodeLength = 3;
      final areaCodeSubstring =
          numbersOnly.substring(sourceIndex, areaCodeLength + sourceIndex);
      areaCode = '($areaCodeSubstring)';
      sourceIndex += areaCodeLength;
    }

    // Prefix, 3 characters
    const prefixLength = 3;
    final prefix =
        numbersOnly.substring(sourceIndex, prefixLength + sourceIndex);
    sourceIndex += prefixLength;

    // Suffix, 4 characters
    const suffixLength = 4;
    final suffix =
        numbersOnly.substring(sourceIndex, suffixLength + sourceIndex);

    return '$leadingOne$areaCode $prefix-$suffix';
  } else {
    return null;
  }
}

final RegExp _emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

String? emailValidator(String? emailInput,
    {bool isRequired = false, String errorMessage = 'Invalid Email Address'}) {
  if (!isRequired && (emailInput == null || emailInput.isEmpty)) {
    return null;
  }

  return !_emailRegex.hasMatch(emailInput!) ? errorMessage : null;
}

String numberValueAsString(String text, {int precision = 0}) {
  List<String> parts = _getOnlyNumbers(text).split('').toList(growable: true);

  if (precision > 0) {
    if (parts.length > precision) {
      parts.insert(parts.length - precision, '.');
    } else if (parts.length < precision) {
      final diff = precision - parts.length;
      List.generate(diff, (index) => index).forEach(
        (element) => parts.insert(0, element.toString()),
      );
      parts.insert(0, '.');
    } else if (parts.length == precision) {
      parts.insert(0, '0.');
    }
  }

  return parts.join();
}

double numberValue(String text, {int precision = 2}) {
  return double.parse(numberValueAsString(text, precision: precision));
}

String _getOnlyNumbers(String text) {
  String cleanedText = text;

  var onlyNumbersRegex = RegExp(r'[^\d]');

  return cleanedText.replaceAll(onlyNumbersRegex, '');
}

double parseDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  } else {
    return value;
  }
}

final NumberFormat percentageFormatter = NumberFormat.percentPattern();
