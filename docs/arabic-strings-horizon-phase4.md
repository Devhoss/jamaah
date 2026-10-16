# Arabic strings added in Horizon Phase 4 (Settings) — for review

Draft Arabic (Modern Standard Arabic), 2026-10-16. Edit the Arabic in `tool/arabic_strings.py`,
then run it, `flutter gen-l10n` and `tool/gen_arabic_digits.py`.

## New strings

| # | Key | English | العربية (draft) |
|---|---|---|---|
| 1 | `settingsBack` | Back | رجوع |
| 2 | `settingsGroupEveryDay` | Every day | كل يوم |
| 3 | `settingsGroupPreferences` | Preferences | التفضيلات |
| 4 | `settingsGroupHelp` | Help | المساعدة |
| 5 | `settingsLanguageLook` | Language and look | اللغة والمظهر |
| 6 | `settingsHelpAbout` | Help and about | المساعدة وعن التطبيق |
| 7 | `settingsHubFooter` | Iqama times live on each mosque, in the Mosques tab, not here. | أوقات الإقامة محفوظة في كل مسجد، في تبويب «المساجد»، لا هنا. |
| 8 | `settingsPrayerTimesSummary` | {method} · Asr {asr} | {method} · العصر {asr} |
| 9 | `settingsAlertsSummary` | {sound} · {on} of {total} on | {sound} · {on} من {total} مفعّلة |
| 10 | `settingsSummaryPair` | {first} · {second} | {first} · {second} |
| 11 | `settingsRemindersPausedShort` | All paused | كلها موقوفة مؤقتًا |
| 12 | `settingsNoActiveMosque` | No active mosque | لا مسجد نشط |
| 13 | `travelSummaryOff` | Off | متوقف |
| 14 | `travelSummaryOn` | On | مفعّل |
| 15 | `travelSummaryFollowing` | On · following your location | مفعّل · يتبع موقعك |
| 16 | `settingsHelpSummary` | Introduction, late alerts, about | المقدمة، والتنبيهات المتأخرة، وعن التطبيق |
| 17 | `settingsPrayerTimesLead` | How the times on Today are worked out. | كيف تُحسب الأوقات في «اليوم». |
| 18 | `settingsAlertsLead` | What you hear at each Adhan. | ما تسمعه عند كل أذان. |
| 19 | `settingsRemindersLead` | How the reminder before your mosque’s Iqama sounds. | صوت التذكير الذي يسبق إقامة مسجدك. |
| 20 | `settingsTravelLead` | Times that follow you on a journey. | أوقات تتبعك في سفرك. |
| 21 | `settingsLanguageLookLead` | The app’s language and theme. | لغة التطبيق ومظهره. |
| 22 | `settingsHelpLead` | Getting started, late alerts, and this build. | البداية، والتنبيهات المتأخرة، وهذا الإصدار. |
| 23 | `extraOnTodaySection` | Extra times on Today | أوقات إضافية في «اليوم» |
| 24 | `extraAlertsAndTiming` | Alerts and timing | التنبيهات والتوقيت |
| 25 | `extraNoAlerts` | No alerts | بلا تنبيهات |
| 26 | `extraAlertsFor` | Alerts: {names} | التنبيهات: {names} |
| 27 | `settingsAdvanced` | Advanced | متقدّم |
| 28 | `highLatitudeLead` | When the night is short, Fajr and Isha need a rule. | حين يقصر الليل، يحتاج الفجر والعشاء إلى قاعدة. |
| 29 | `alertsEachPrayer` | Each prayer | كل صلاة |
| 30 | `alertsAlsoFromToday` | Also from Today: tap the sound beside any prayer. | ومن «اليوم» أيضًا: انقر الصوت بجانب أي صلاة. |
| 31 | `alertsRecordings` | Recordings | التسجيلات |
| 32 | `alertsSilentSection` | On the lock screen and on silent | على شاشة القفل وفي الوضع الصامت |
| 33 | `settingsRemindersOnMosque` | Iqama times and which prayers remind you are set on each mosque. | أوقات الإقامة والصلوات التي تذكّرك تُضبط في كل مسجد. |
| 34 | `followNeedsTravel` | Available while travel mode is on. | متاح أثناء تفعيل وضع السفر. |
| 35 | `travelInFlightValue` | Prayer times and the Qibla on a plane | أوقات الصلاة والقبلة على متن الطائرة |
| 36 | `themeSkyNote` | The sky always follows the time of day. Dark keeps it dimmer. | السماء تتبع وقت النهار دائمًا، والوضع الداكن يجعلها أخفت. |
| 37 | `helpLateAlerts` | Alerts arriving late? | هل تصل التنبيهات متأخرة؟ |
| 38 | `helpLateAlertsLead` | Most often the phone is saving battery. | غالبًا ما يكون الهاتف يوفّر البطارية. |
| 39 | `helpBatteryTitle` | Battery use | استخدام البطارية |
| 40 | `helpCheckTitle` | Check what is scheduled | تحقّق ممّا هو مجدول |
| 41 | `helpCheckBody` | The list shows every alert and reminder waiting on this phone, and says if a permission is missing. | تعرض القائمة كل تنبيه وتذكير ينتظر على هذا الهاتف، وتخبرك إن كان هناك إذن ناقص. |
| 42 | `helpAbout` | About | عن التطبيق |
| 43 | `methodListLead` | Each method's angles, and where it is used. | زوايا كل طريقة، وأين تُستعمل. |

## Changed by spec §7 (renamed or shortened)

| Key | English (new) | العربية (new draft) |
|---|---|---|
| `settingsHighLatitude` | Far north or south | أقصى الشمال أو الجنوب |
| `settingsAdjustments` | Adjust times by minutes | ضبط الأوقات بالدقائق |
| `settingsPauseAllIqamaHint` | From every mosque. Iqama times are kept, and Adhan alerts carry on. | من كل المساجد. تبقى أوقات الإقامة محفوظة، وتستمر تنبيهات الأذان. |
