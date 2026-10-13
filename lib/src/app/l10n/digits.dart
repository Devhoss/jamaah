/// Arabic-Indic digits for the Arabic UI (2026-10-14).
///
/// The app's Arabic shows ٠١٢٣٤٥٦٧٨٩, as is usual in Kuwait. Dates and times
/// are formatted with the `ar_EG` data for the same reason (plain `ar` in intl
/// gives Western digits, and intl has no `ar_KW`); nothing in the UI says
/// Egypt.
library;

const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';

/// A number followed by a degree sign.
final _degrees = RegExp('[٠-٩][٠-٩.,٬٫]*°');

/// [text] with every Western digit replaced by its Arabic-Indic form.
///
/// A number with a degree sign is also kept as one left-to-right unit (with
/// Unicode isolates), so in a right-to-left line the sign stays after the
/// number (١٣٦°) instead of jumping before it (°١٣٦).
String arabicDigits(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final i = rune >= 0x30 && rune <= 0x39 ? rune - 0x30 : -1;
    out.write(i >= 0 ? _arabicIndic[i] : String.fromCharCode(rune));
  }
  return out.toString().replaceAllMapped(
    _degrees,
    (m) => '\u2066${m[0]}\u2069',
  );
}

/// [text] as the locale [languageCode] shows digits.
String localDigits(String text, String languageCode) =>
    languageCode == 'ar' ? arabicDigits(text) : text;

/// The intl locale that formats dates and numbers for [languageCode]: Arabic
/// uses `ar_EG`, whose data carries Arabic-Indic digits.
String formattingLocale(String languageCode) =>
    languageCode == 'ar' ? 'ar_EG' : languageCode;
