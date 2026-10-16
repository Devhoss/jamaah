# Arabic strings added in Horizon Phase 6 — for review

Draft Arabic (Modern Standard Arabic), 2026-10-16. Edit the Arabic in `tool/arabic_strings.py`,
then run it, `flutter gen-l10n` and `tool/gen_arabic_digits.py`.

## Onboarding: on-time alerts (Android's Alarms & reminders)

| # | Key | English | العربية (draft) |
|---|---|---|---|
| 1 | `onbExactNote` | For alerts at the very minute, Android also asks you to let Jama’ah set alarms. Without it, an alert can come a few minutes late. | لتصل التنبيهات في دقيقتها تمامًا، يطلب أندرويد أيضًا أن تسمح لتطبيق «جماعة» بضبط المنبّهات. ومن دون ذلك قد يتأخّر التنبيه بضع دقائق. |
| 2 | `onbExactAllow` | Allow on-time alerts | اسمح بالتنبيهات في وقتها |
| 3 | `onbExactHow` | Turn on the switch on the next screen, then come back. | فعّل المفتاح في الشاشة التالية، ثم عُد. |
| 4 | `onbExactAllowed` | On-time alerts allowed | التنبيهات في وقتها مسموح بها |

The brand lockup reuses `appTitle` (Jama’ah / جماعة).
