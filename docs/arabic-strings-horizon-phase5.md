# Arabic strings added in Horizon Phase 5 — for review

Draft Arabic (Modern Standard Arabic), 2026-10-16. Edit the Arabic in `tool/arabic_strings.py`,
then run it, `flutter gen-l10n` and `tool/gen_arabic_digits.py`.

## Qibla

| # | Key | English | العربية (draft) |
|---|---|---|---|
| 1 | `compassEast` | E | ق |
| 2 | `compassWest` | W | غ |
| 3 | `qiblaLead` | From {place} · {distance} km to the Kaaba | من {place} · {distance} كم إلى الكعبة |
| 4 | `compassPointNorth` | North | الشمال |
| 5 | `compassPointNorthEast` | North-east | الشمال الشرقي |
| 6 | `compassPointEast` | East | الشرق |
| 7 | `compassPointSouthEast` | South-east | الجنوب الشرقي |
| 8 | `compassPointSouth` | South | الجنوب |
| 9 | `compassPointSouthWest` | South-west | الجنوب الغربي |
| 10 | `compassPointWest` | West | الغرب |
| 11 | `compassPointNorthWest` | North-west | الشمال الغربي |
| 12 | `compassLowerNorth` | north | الشمال |
| 13 | `compassLowerEast` | east | الشرق |
| 14 | `compassLowerSouth` | south | الجنوب |
| 15 | `compassLowerWest` | west | الغرب |
| 16 | `compassLeanToward` | {point}, a little towards the {toward} | {point}، مع ميل قليل نحو {toward} |
| 17 | `compassLeanMore` | {point}, a little more {more} than {less} | {point}، أقرب قليلًا إلى {more} منه إلى {less} |
| 18 | `qiblaNoCompassHint` | This phone has no compass, so the arrow can’t follow you. Line it up with a direction you know, such as where the sun sets. | لا بوصلة في هذا الهاتف، فلا يستطيع السهم أن يتبعك. وجّهه نحو اتجاه تعرفه، كجهة غروب الشمس. |
| 19 | `qiblaNeedsMoment` | The compass needs a moment | البوصلة تحتاج إلى لحظة |
| 20 | `qiblaSteadyNow` | It’s steady now | استقرّت البوصلة الآن |

## Onboarding

| # | Key | English | العربية (draft) |
|---|---|---|---|
| 21 | `onbLanguageLabel` | Language · اللغة | اللغة · Language |
| 22 | `onbLanguageLater` | You can change it later in Settings. | يمكنك تغييرها لاحقًا من الإعدادات. |
| 23 | `onbPlaceBody` | Prayer times are worked out on your phone from your place. An approximate location is enough, and it never leaves your phone. | تُحسب مواقيت الصلاة على هاتفك من مكانك. يكفي موقع تقريبي، ولا يغادر هاتفك أبدًا. |
| 24 | `onbPlaceDetails` | Method: {method} · next Adhan {prayer} {time} | الطريقة: {method} · الأذان القادم {prayer} {time} |
| 25 | `onbPlaceNotRight` | Not right? Choose a city | ليس صحيحًا؟ اختر مدينة |
| 26 | `onbMosqueRowOpen` | A row of worshippers, with one place open for you | صفّ من المصلّين، فيه مكان شاغر لك |
| 27 | `onbMosqueRowFull` | A full row, with you in it | صفّ مكتمل، وأنت فيه |
| 28 | `onbMosqueAdded` | {mosque} added | أُضيف {mosque} |
| 29 | `onbMosqueAddedBody` | Its Iqama times are not configured yet. Set them from the Mosques tab whenever you are ready. | لم تُضبط أوقات الإقامة فيه بعد. اضبطها من تبويب «المساجد» متى شئت. |
| 30 | `onbAlertsFiveHint` | Fajr, Dhuhr, Asr, Maghrib and Isha | الفجر والظهر والعصر والمغرب والعشاء |
| 31 | `onbAllowNote` | Android will ask if Jama’ah may send notifications. Without it, alerts can’t appear. | سيسألك أندرويد إن كان يُسمح لتطبيق «جماعة» بإرسال الإشعارات. ومن دون ذلك لا تظهر التنبيهات. |
| 32 | `onbNotificationsAllowed` | Notifications allowed | الإشعارات مسموح بها |
| 33 | `onbBatterySettings` | Battery settings | إعدادات البطارية |
| 34 | `onbTravelOnSub` | On: times follow you | مفعّل: الأوقات تتبعك |
| 35 | `onbTravelOffSub` | Off: times stay where you set them | متوقف: تبقى الأوقات حيث ضبطتها |
| 36 | `onbTravelSame` | The same switch sits at the top of Today. | المفتاح نفسه موجود أعلى «اليوم». |

## In flight

| # | Key | English | العربية (draft) |
|---|---|---|---|
| 37 | `inFlightStartTitle` | Prayer times at 11,000 metres | مواقيت الصلاة على ارتفاع ١١٬٠٠٠ متر |
| 38 | `inFlightStartLead` | Worked out from your phone’s GPS. It works in airplane mode, with no network. | تُحسب من نظام GPS في هاتفك، وهو يعمل في وضع الطيران دون شبكة. |
| 39 | `inFlightWindowNote` | Sit by a window if you can. The first fix can take a few minutes. | اجلس قرب النافذة إن استطعت. قد يستغرق تحديد الموقع الأول بضع دقائق. |
| 40 | `inFlightLookingTitle` | Looking for satellites | نبحث عن الأقمار الصناعية |
| 41 | `inFlightKeepLooking` | Keep the phone near a window, screen up. | أبقِ الهاتف قرب النافذة وشاشته إلى الأعلى. |
| 42 | `inFlightAircraftTime` | Aircraft time {time} ({offset}), from your position | توقيت الطائرة {time} ({offset})، حسب موقعك |
| 43 | `inFlightPosition` | {lat} · {lon} | {lat} · {lon} |
| 44 | `inFlightLatNorth` | {degrees}° N | {degrees}° ش |
| 45 | `inFlightLatSouth` | {degrees}° S | {degrees}° ج |
| 46 | `inFlightLonEast` | {degrees}° E | {degrees}° ق |
| 47 | `inFlightLonWest` | {degrees}° W | {degrees}° غ |
| 48 | `inFlightAlongTitle` | Along the route | على طول الرحلة |
| 49 | `inFlightEstimates` | Estimates | تقديرات |
| 50 | `inFlightHeadingHint` | Aircraft heading: from the seat-back map, or ask the crew. | اتجاه الطائرة: من خريطة المقعد، أو اسأل الطاقم. |
| 51 | `inFlightQiblaWords` | {words} · {degrees}° | {words} · {degrees}° |
| 52 | `qiblaDirStraightAhead` | Straight ahead | أمامك مباشرة |
| 53 | `qiblaDirAheadRight` | Ahead, to your right | أمامك، إلى يمينك |
| 54 | `qiblaDirRight` | To your right | إلى يمينك |
| 55 | `qiblaDirBehindRight` | Behind you, to the right | خلفك، إلى اليمين |
| 56 | `qiblaDirBehind` | Behind you | خلفك |
| 57 | `qiblaDirBehindLeft` | Behind you, to the left | خلفك، إلى اليسار |
| 58 | `qiblaDirLeft` | To your left | إلى يسارك |
| 59 | `qiblaDirAheadLeft` | Ahead, to your left | أمامك، إلى يسارك |

## Full-screen Adhan

| # | Key | English | العربية (draft) |
|---|---|---|---|
| 60 | `adhanScreenKicker` | It’s time for | حان وقت |
| 61 | `adhanScreenAdhanAt` | Adhan · {time} | الأذان · {time} |
| 62 | `adhanScreenIqamaIn` | Iqama at {mosque} · {time}, {countdown} | الإقامة في {mosque} · {time}، {countdown} |
| 63 | `adhanScreenIqamaAt` | Iqama at {mosque} · {time} | الإقامة في {mosque} · {time} |
| 64 | `adhanScreenNoIqama` | No Iqama set at {mosque} | لا وقت إقامة محدّد في {mosque} |
| 65 | `adhanScreenHint` | Volume keys or turning the phone face down also stop it. | أزرار الصوت أو قلب الهاتف على وجهه توقفه أيضًا. |
| 66 | `adhanScreenStopped` | Adhan stopped | توقّف الأذان |
| 67 | `adhanScreenDismiss` | Dismiss | إغلاق |
| 68 | `adhanScreenStopLabel` | Stop the {prayer} Adhan | أوقف أذان {prayer} |

## Onboarding copy reworded (spec §4.6 and §7)

| Key | English (new) | العربية (new draft) |
|---|---|---|
| `onbWelcomeTagline` | Pray together, on time. | نصلّي معًا، في وقتها. |
| `onbWelcomeBody` | Know when to pray. Know when your mosque starts. Get a nudge before the congregation. | اعرف متى تصلّي، ومتى تبدأ الجماعة في مسجدك، وتلقَّ تذكيرًا قبلها. |
| `onbMosqueBody` | Jama’ah means praying together. Add the mosque you pray at to see when its congregation starts, and get a nudge before it. | الجماعة تعني الصلاة معًا. أضف المسجد الذي تصلّي فيه لترى متى تبدأ جماعته، ولتتلقّى تذكيرًا قبلها. |
| `onbAlertsBody` | An alert at each Adhan. You can choose the sound for each prayer later, from Today. | تنبيه عند كل أذان. يمكنك اختيار صوت كل صلاة لاحقًا من «اليوم». |
| `onbAlertsSwitch` | Alerts for the five prayers | تنبيهات الصلوات الخمس |
| `onbAlertsBattery` | Some phones stop apps in the background to save battery. If an alert ever comes late, let Jama’ah run unrestricted. | تُوقف بعض الهواتف التطبيقات في الخلفية لتوفير البطارية. إذا تأخّر تنبيه يومًا، فاسمح لتطبيق «جماعة» بالعمل دون قيود. |
| `onbTravelBody` | Travel mode follows your location, so times and the Qibla stay right wherever you land. On a plane it can show prayer times along the route. | يتبع وضع السفر موقعك، فتبقى الأوقات والقبلة صحيحة حيثما حللت. وعلى متن الطائرة يمكنه عرض مواقيت الصلاة على طول الرحلة. |
| `onbTravelSwitch` | Travel mode | وضع السفر |

Note: the compass letters are ش (N), ق (E), ج (S), غ (W).
