# Arabic strings added in Horizon Phase 3 (Mosques) and the A53 fixes — for review

Draft Arabic (Modern Standard Arabic), 2026-10-16. Edit the Arabic in `tool/arabic_strings.py`,
then run it, `flutter gen-l10n` and `tool/gen_arabic_digits.py`.

| # | Key | English | العربية (draft) |
|---|---|---|---|
| 1 | `sunLabelCombined` | {prayer} · {time} | {prayer} · {time} |
| 2 | `placeNearCity` | Near {city} | قرب {city} |
| 3 | `mosquesLead` | Today and your Jama’ah reminders follow your active mosque, now {mosque}. | يتبع «اليوم» وتذكيرات الجماعة مسجدك النشط، وهو الآن {mosque}. |
| 4 | `mosquesLeadNoActive` | Make one mosque active and Today follows it. | اجعل أحد المساجد نشطًا ليتبعه «اليوم». |
| 5 | `mosquesFindNearby` | Find nearby | ابحث بالقرب منك |
| 6 | `mosquesAddManually` | Add manually | أضف يدويًا |
| 7 | `mosqueSourceGoogleUnverified` | From Google Maps · not verified | من خرائط Google · غير موثّق |
| 8 | `mosqueSourceOsmUnverified` | From OpenStreetMap · not verified | من OpenStreetMap · غير موثّق |
| 9 | `mosqueNoIqamaYet` | No Iqama set yet | لم تُحدَّد أي إقامة بعد |
| 10 | `mosqueActiveLong` | Active · Today uses this mosque | نشط · «اليوم» يستخدم هذا المسجد |
| 11 | `mosqueMakeActive` | Make active | اجعله نشطًا |
| 12 | `mosqueMadeActive` | {mosque} is now your active mosque | أصبح {mosque} مسجدك النشط |
| 13 | `mosquesFooter` | Mosques found online show where they came from and are not verified. Your Iqama times stay on this phone. | المساجد التي تُعثر عليها عبر الإنترنت تُظهر مصدرها وهي غير موثّقة. أوقات الإقامة التي تُدخلها تبقى على هذا الهاتف. |
| 14 | `mosquesEmptyTitle` | There’s a place for you | لك مكانٌ في الصف |
| 15 | `mosquesEmptyBody` | Add the mosque you pray at. Jama’ah will show when its congregation starts and remind you before it. | أضف المسجد الذي تصلّي فيه. سيُظهر «جماعة» موعد بدء صلاة الجماعة فيه ويذكّرك قبلها. |
| 16 | `mosquesEmptyFind` | Find mosques nearby | ابحث عن مساجد قريبة |
| 17 | `mosquesEmptyAdd` | Add one yourself | أضف مسجدًا بنفسك |
| 18 | `mosquesEmptyNote` | You enter its Iqama times. Nothing is guessed, and nothing leaves your phone. | أنت من يُدخل أوقات الإقامة. لا شيء يُخمَّن، ولا شيء يغادر هاتفك. |
| 19 | `mosqueRowSemantics` | {mosque}. {source}. {count} | {mosque}. {source}. {count} |
| 20 | `mosqueKicker` | Your mosque | مسجدك |
| 21 | `mosqueNextJamaah` | Next Jama’ah · {prayer} {time} · {relative} | الجماعة القادمة · {prayer} {time} · {relative} |
| 22 | `mosqueNoNextJamaah` | No more Jama’ah set for today | لا جماعة أخرى محدّدة لليوم |
| 23 | `mosquePauseTitle` | Pause Jama’ah reminders | إيقاف تذكيرات الجماعة مؤقتًا |
| 24 | `mosquePauseHint` | Your Iqama times and settings are kept. | تبقى أوقات الإقامة وإعداداتك محفوظة. |
| 25 | `scheduleSection` | Iqama schedule | جدول الإقامة |
| 26 | `scheduleTapHint` | Tap a prayer to set it | اضغط على صلاة لتحديدها |
| 27 | `rowAdhanPlus` | {minutes, plural, =1{Adhan + 1 min} other{Adhan + {minutes} min}} | {minutes, plural, =1{الأذان + دقيقة} =2{الأذان + دقيقتين} few{الأذان + {minutes} دقائق} many{الأذان + {minutes} دقيقة} other{الأذان + {minutes} دقيقة}} |
| 28 | `rowFixedTime` | Fixed time | وقت ثابت |
| 29 | `rowPausedReminder` | Paused · Reminder at {time} | متوقف مؤقتًا · التذكير {time} |
| 30 | `reminderSwitchNeedsIqama` | {prayer} Jama’ah reminder, available once an Iqama time is set | تذكير جماعة {prayer}، متاح بعد تحديد وقت الإقامة |
| 31 | `scheduleNeverFills` | The app never fills in an Iqama. | التطبيق لا يملأ أي إقامة من عنده. |
| 32 | `removeThisMosque` | Remove this mosque | إزالة هذا المسجد |
| 33 | `mosqueBack` | Back to Mosques | العودة إلى المساجد |
| 34 | `iqamaRowSet` | Edit {prayer} Iqama | تعديل إقامة {prayer} |
| 35 | `iqamaRowUnset` | Set {prayer} Iqama | تحديد إقامة {prayer} |
| 36 | `scheduleFooter` | Set by you · last updated {date}. The app never fills in an Iqama. | حدّدتها أنت · آخر تحديث {date}. التطبيق لا يملأ أي إقامة من عنده. |
| 37 | `iqamaEditorSub` | {mosque} · Adhan {time} today | {mosque} · الأذان {time} اليوم |
| 38 | `iqamaEditorSubFriday` | {mosque} · Fridays, in place of Dhuhr | {mosque} · أيام الجمعة، بدل الظهر |
| 39 | `iqamaModeAfterDesc` | Moves with the Adhan | يتحرّك مع الأذان |
| 40 | `iqamaModeFixedDesc` | Same time every day | الوقت نفسه كل يوم |
| 41 | `iqamaMinutesEmpty` | Choose how many minutes after the Adhan this mosque starts. Nothing is saved until you do. | اختر كم دقيقة بعد الأذان تبدأ الإقامة في هذا المسجد. لا يُحفظ شيء حتى تختار. |
| 42 | `iqamaFixedEmptyNote` | Nothing is saved until you choose a time. | لا يُحفظ شيء حتى تختار وقتًا. |
| 43 | `iqamaFixedNote` | The same time every day, whatever the Adhan. | الوقت نفسه كل يوم، أيًّا كان وقت الأذان. |
| 44 | `iqamaReminderTitle` | Jama’ah reminder | تذكير الجماعة |
| 45 | `iqamaReminderHint` | A nudge before the congregation starts | تنبيه قبل أن تبدأ صلاة الجماعة |
| 46 | `iqamaSaved` | {prayer} Iqama saved | حُفظت إقامة {prayer} |
| 47 | `clearThisIqama` | Clear this Iqama | مسح هذه الإقامة |
| 48 | `iqamaFewerMinutes` | One minute less | دقيقة أقل |
| 49 | `iqamaMoreMinutes` | One minute more | دقيقة أكثر |
| 50 | `iqamaEarlier` | {minutes, plural, =1{1 minute earlier} other{{minutes} minutes earlier}} | {minutes, plural, =1{تقديم دقيقة} =2{تقديم دقيقتين} few{تقديم {minutes} دقائق} many{تقديم {minutes} دقيقة} other{تقديم {minutes} دقيقة}} |
| 51 | `iqamaLater` | {minutes, plural, =1{1 minute later} other{{minutes} minutes later}} | {minutes, plural, =1{تأخير دقيقة} =2{تأخير دقيقتين} few{تأخير {minutes} دقائق} many{تأخير {minutes} دقيقة} other{تأخير {minutes} دقيقة}} |
