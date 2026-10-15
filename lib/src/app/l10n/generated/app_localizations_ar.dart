// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'جماعة';

  @override
  String get tabToday => 'اليوم';

  @override
  String get tabMosques => 'المساجد';

  @override
  String get tabQibla => 'القبلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get remove => 'إزالة';

  @override
  String get notConfigured => 'غير محددة';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get todayLoading => 'جارٍ تحميل يومك…';

  @override
  String get todayNeedsPlaceTitle => 'حدّد موقعك';

  @override
  String get todayNeedsPlaceBody =>
      'تُحسب مواقيت الصلاة للمكان الذي أنت فيه، على هذا الجهاز. اختر مكانك للبدء.';

  @override
  String get todayChoosePlace => 'اختر مكانك';

  @override
  String get todayErrorTitle => 'تعذّرت قراءة إعداداتك المحفوظة';

  @override
  String get todayErrorBody =>
      'لم يتمكن التطبيق من فتح بياناته على هذا الجهاز. لم يُفقد شيء — حاول مرة أخرى، أو اختر موقعك.';

  @override
  String get todaySectionTimes => 'مواقيت الصلاة (الأذان)';

  @override
  String get nextPrayerAdhan => 'الصلاة القادمة · الأذان';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get tagNext => 'القادمة';

  @override
  String prayerAtTime(String prayer, String time) {
    return '$prayer $time';
  }

  @override
  String countdownHours(int hours, int minutes) {
    return 'بعد $hours س و$minutes د';
  }

  @override
  String countdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'بعد $minutes دقيقة',
      many: 'بعد $minutes دقيقة',
      few: 'بعد $minutes دقائق',
      two: 'بعد دقيقتين',
      one: 'بعد دقيقة',
    );
    return '$_temp0';
  }

  @override
  String nextIqamaLabel(String mosque) {
    return 'الإقامة القادمة · $mosque';
  }

  @override
  String get noIqamaLeftToday => 'لا توجد إقامة أخرى اليوم.';

  @override
  String rowIqama(String time) {
    return 'الإقامة $time';
  }

  @override
  String reminderBeforeIqama(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'تذكير قبل $minutes دقيقة',
      many: 'تذكير قبل $minutes دقيقة',
      few: 'تذكير قبل $minutes دقائق',
      two: 'تذكير قبل دقيقتين',
      one: 'تذكير قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get reminderOffForPrayer => 'لا يوجد تذكير لهذه الصلاة';

  @override
  String highLatitudeNote(String prayers, String rule) {
    return 'في هذا الخط من العرض، يُحسب $prayers بقاعدة $rule.';
  }

  @override
  String twoNames(String first, String second) {
    return '$first و$second';
  }

  @override
  String get ruleMiddleOfTheNight => 'منتصف الليل';

  @override
  String get ruleSeventhOfTheNight => 'سُبع الليل';

  @override
  String get ruleTwilightAngle => 'زاوية الشفق';

  @override
  String estimatedFromLatitudeNote(String latitude) {
    return 'لا تشرق الشمس ولا تغرب هنا اليوم، لذا قُدّرت هذه المواقيت من خط العرض $latitude الأقرب إلى خط الاستواء.';
  }

  @override
  String get noTimeToday => 'لا يوجد وقت اليوم';

  @override
  String get timesUnavailableTitle => 'لا توجد مواقيت لهذا اليوم';

  @override
  String get timesUnavailableBody =>
      'لا تعبر الشمس الأفق هنا اليوم، فلا يمكن حساب وقت صلاة صحيح. اختر مدينة قريبة، أو يومًا فيه شروق عادي.';

  @override
  String get addMosqueTitle => 'أضف مسجدك';

  @override
  String get addMosqueBody =>
      'اختر مسجدًا وأدخل أوقات الإقامة فيه لتظهر هنا. لا نخمّنها أبدًا.';

  @override
  String mosqueHasNoIqama(String mosque) {
    return 'لم تُحدَّد أوقات الإقامة في $mosque بعد. اضغط لتحديدها.';
  }

  @override
  String get reminderOnSemantics => 'تذكير الجماعة مفعّل';

  @override
  String get aboutBody =>
      'نسخة مبكرة. تُحسب مواقيت الصلاة على هذا الجهاز، وتُدخل أوقات الإقامة بنفسك لكل مسجد.';

  @override
  String qiblaFrom(String place) {
    return 'من $place';
  }

  @override
  String qiblaDegrees(String degrees) {
    return '$degrees°';
  }

  @override
  String qiblaFromNorth(String degrees) {
    return '$degrees° من الشمال الحقيقي';
  }

  @override
  String qiblaTurnRight(String degrees) {
    return 'استدر $degrees° إلى اليمين';
  }

  @override
  String qiblaTurnLeft(String degrees) {
    return 'استدر $degrees° إلى اليسار';
  }

  @override
  String get qiblaAligned => 'أنت متجه إلى القبلة';

  @override
  String qiblaDistance(String distance) {
    return '$distance كم إلى الكعبة';
  }

  @override
  String get qiblaHoldFlat =>
      'أمسك هاتفك مستويًا، بعيدًا عن المعادن والمغناطيس.';

  @override
  String qiblaDeclinationNote(String degrees) {
    return 'القياس من الشمال الحقيقي. البوصلة تقيس الشمال المغناطيسي، لذا صُحّح فرق $degrees° لهذا المكان.';
  }

  @override
  String get qiblaMagneticNote =>
      'القياس من الشمال المغناطيسي، وقد يختلف عن الشمال الحقيقي ببضع درجات.';

  @override
  String get qiblaNeedsCalibration => 'البوصلة غير دقيقة الآن.';

  @override
  String get qiblaCalibrate => 'طريقة المعايرة';

  @override
  String get qiblaCalibrateTitle => 'معايرة البوصلة';

  @override
  String get qiblaCalibrateBody =>
      'حرّك هاتفك ببطء على شكل الرقم 8 عدة مرات، بعيدًا عن المعادن والمغناطيس. يستقر الاتجاه عندما تصبح البوصلة دقيقة.';

  @override
  String get qiblaCalibrateDone => 'تم';

  @override
  String get qiblaNoCompassTitle => 'البوصلة غير متاحة';

  @override
  String qiblaNoCompassBody(String degrees, String place) {
    return 'القبلة على بُعد $degrees° باتجاه عقارب الساعة من الشمال الحقيقي في $place. استخدم أي بوصلة أو تطبيق خرائط واتجه بهذه الزاوية.';
  }

  @override
  String get qiblaNeedsPlaceTitle => 'حدّد موقعك';

  @override
  String get qiblaNeedsPlaceBody =>
      'يُحسب اتجاه القبلة على هذا الجهاز من مكانك. اختر مكانك للبدء.';

  @override
  String qiblaDialLabel(String degrees) {
    return 'البوصلة. القبلة على بُعد $degrees° من الشمال الحقيقي.';
  }

  @override
  String get locationSheetTitle => 'أين أنت؟';

  @override
  String get locationSheetBody =>
      'يحسب التطبيق مواقيت الصلاة للمكان الذي أنت فيه، على هذا الجهاز. لا يوجد حساب ولا يُرفع أي شيء.';

  @override
  String get locationSheetCoarse =>
      'تحتاج مواقيت الصلاة إلى موقع تقريبي فقط، على مستوى المدينة؛ فالمواقيت داخل المدينة الواحدة تختلف بدقائق قليلة. أما البحث عن المساجد القريبة فيطلب الموقع الدقيق بشكل منفصل.';

  @override
  String get locationUseDevice => 'استخدم موقعي';

  @override
  String get locationChooseCity => 'اختر مدينة';

  @override
  String get locationRequesting => 'جارٍ تحديد موقعك…';

  @override
  String get locationCurrentPlace => 'الموقع الحالي';

  @override
  String get placeRenameAction => 'سمِّ هذا المكان';

  @override
  String get placeRenameTitle => 'أعطِ هذا المكان اسمًا';

  @override
  String get placeRenameHint => 'مثلًا: المنزل';

  @override
  String get locationDenied =>
      'رفضت إذن الموقع، ولا بأس في ذلك — اختر مدينتك وستكون المواقيت صحيحة.';

  @override
  String get locationPermanentlyDenied =>
      'الموقع متوقف لهذا التطبيق في إعدادات جهازك. يمكنك تغيير ذلك هناك، أو اختيار مدينتك الآن.';

  @override
  String get locationServiceDisabled =>
      'خدمات الموقع متوقفة على هذا الجهاز. اختر مدينتك، أو شغّل الموقع وحاول مرة أخرى.';

  @override
  String get locationTimeout =>
      'لم يستجب جهازك في الوقت المحدد. يمكنك المحاولة مرة أخرى، أو اختيار مدينتك.';

  @override
  String get locationUnavailable =>
      'تعذّرت قراءة موقعك الآن. اختر مدينتك بدلًا من ذلك.';

  @override
  String get locationOpenSettings => 'فتح إعدادات التطبيق';

  @override
  String get locationTryAgain => 'حاول مرة أخرى';

  @override
  String get cityListTitle => 'اختر مدينة';

  @override
  String get cityListPlaceholderNote =>
      'هذه القائمة مضمّنة في التطبيق، فتعمل دون اتصال. وهي قائمة مبدئية للبدء، وليست دليلًا شاملًا. اختر أقرب مدينة إليك.';

  @override
  String get cityListSearchHint => 'بحث';

  @override
  String get cityListNoMatches =>
      'لا توجد مدينة مطابقة. اختر أقرب مدينة — فالمواقيت تختلف بدقائق قليلة فقط.';

  @override
  String currentPlaceLabel(String place) {
    return 'مواقيت الصلاة في $place';
  }

  @override
  String get mosquesTitle => 'المساجد';

  @override
  String get mosquesSubtitle => 'أوقات الإقامة خاصة بكل مسجد.';

  @override
  String get findNearbyMosques => 'ابحث عن مساجد قريبة';

  @override
  String get addMosqueManually => 'أضف مسجدًا يدويًا';

  @override
  String get savedMosquesHeader => 'المحفوظة';

  @override
  String get noSavedMosques =>
      'لا توجد مساجد محفوظة بعد. أضف مسجدك، ثم أدخل أوقات الإقامة فيه.';

  @override
  String get tagActive => 'النشط';

  @override
  String get iqamaStatusAll => 'أوقات الإقامة محددة';

  @override
  String iqamaStatusPartial(int count, int total) {
    return 'حُدّدت إقامة $count من $total';
  }

  @override
  String get iqamaStatusNone => 'الإقامة غير محددة';

  @override
  String get mosqueSourceManual => 'أضفته بنفسك';

  @override
  String get mosqueSourceGoogle => 'من خرائط Google';

  @override
  String get mosqueSourceOsm => 'من OpenStreetMap';

  @override
  String get addMosqueSheetTitle => 'إضافة مسجد';

  @override
  String get addMosqueSheetBody =>
      'يبدأ جدول الإقامة «غير محدد»، وأنت من يُدخل الأوقات.';

  @override
  String get mosqueNameLabel => 'اسم المسجد';

  @override
  String get mosqueAddressLabel => 'العنوان أو المنطقة (اختياري)';

  @override
  String get add => 'إضافة';

  @override
  String get setAsActive => 'اجعله المسجد النشط';

  @override
  String get activeMosqueNote =>
      'تعتمد شاشة اليوم وتذكيرات الجماعة على هذا المسجد.';

  @override
  String get editDetails => 'تعديل التفاصيل';

  @override
  String get editMosqueTitle => 'تعديل المسجد';

  @override
  String iqamaScheduleHeader(String mosque) {
    return 'جدول الإقامة · $mosque';
  }

  @override
  String rowAdhanTime(String time) {
    return 'الأذان $time';
  }

  @override
  String rowReminderAt(String time) {
    return 'التذكير الساعة $time';
  }

  @override
  String rowReminderBeforeMidnight(String time) {
    return 'التذكير الساعة $time، قبل منتصف الليل';
  }

  @override
  String get rowReminderOff => 'التذكير متوقف';

  @override
  String get rowReminderNeedsIqama => 'حدّد وقت الإقامة لإضافة تذكير';

  @override
  String reminderSwitchLabel(String prayer) {
    return 'تذكير الجماعة لصلاة $prayer';
  }

  @override
  String scheduleSetByYou(String date) {
    return 'حدّدته بنفسك · آخر تحديث $date';
  }

  @override
  String get scheduleNothingEntered =>
      'لم تُدخل أي أوقات إقامة بعد. اضغط على صلاة لتحديد وقتها.';

  @override
  String get iqamaScheduleNote =>
      'اضغط على صلاة لتعديلها. أوقات الإقامة تُدخلها بنفسك لهذا المسجد، ولا تؤخذ أبدًا من أوقات الأذان. لا إقامة للشروق.';

  @override
  String get removeMosque => 'إزالة المسجد';

  @override
  String removeMosqueTitle(String mosque) {
    return 'إزالة $mosque؟';
  }

  @override
  String get removeMosqueBody => 'ستُحذف أوقات الإقامة فيه من هذا الجهاز.';

  @override
  String get removeMosqueBodyActive =>
      'ستُحذف أوقات الإقامة فيه من هذا الجهاز. وهو مسجدك النشط، فلن تعرض شاشة اليوم أي مسجد حتى تختار غيره.';

  @override
  String iqamaEditorTitle(String prayer) {
    return 'إقامة $prayer';
  }

  @override
  String iqamaEditorEditing(String mosque) {
    return 'تعديل $mosque';
  }

  @override
  String get iqamaChooseTime => 'اختر وقتًا';

  @override
  String iqamaStartsAtAdhan(String time) {
    return 'الأذان $time · اضغط للتحديد';
  }

  @override
  String get iqamaTimeLabel => 'وقت الإقامة';

  @override
  String get remindMeBefore => 'ذكّرني قبل الإقامة';

  @override
  String get reminderNeedsTime => 'اختر وقت الإقامة أولًا.';

  @override
  String reminderMinutesChip(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get reminderCustom => 'مخصص';

  @override
  String get reminderCustomLabel => 'عدد الدقائق قبلها (1–120)';

  @override
  String get reminderCustomEmpty => 'أدخل عدد الدقائق قبل الإقامة.';

  @override
  String get reminderCustomNotWhole => 'استخدم دقائق كاملة، مثل 20.';

  @override
  String get reminderCustomOutOfRange => 'اختر بين 1 و120 دقيقة.';

  @override
  String get summaryNoTime => 'اختر وقت الإقامة لترى ملخص التذكير.';

  @override
  String summaryReminderOff(String prayer, String time) {
    return '$prayer · الإقامة $time · التذكير متوقف';
  }

  @override
  String summaryReminderAt(String prayer, String time, String reminder) {
    return '$prayer · الإقامة $time · التذكير الساعة $reminder';
  }

  @override
  String summaryReminderBeforeMidnight(
    String prayer,
    String time,
    String reminder,
  ) {
    return '$prayer · الإقامة $time · التذكير الساعة $reminder، قبل منتصف الليل';
  }

  @override
  String get clearIqamaTime => 'مسح وقت الإقامة';

  @override
  String get nearbyTitle => 'المساجد القريبة';

  @override
  String get nearbyExplainTitle => 'ابحث عن المساجد القريبة منك';

  @override
  String get nearbyExplainBody =>
      'نستخدم موقعك الدقيق مرة واحدة لعرض المساجد من حولك. إن أبقيت الموقع تقريبيًا فسيعمل البحث، لكن بدقة أقل.';

  @override
  String nearbyExplainSent(String provider) {
    return 'يُرسَل موقعك إلى $provider لهذا البحث فقط، ولا يحتفظ به التطبيق.';
  }

  @override
  String get providerGoogle => 'خرائط Google';

  @override
  String get providerOsm => 'OpenStreetMap';

  @override
  String get nearbyUseLocation => 'استخدم موقعي';

  @override
  String get nearbySearchCity => 'ابحث حول مدينة';

  @override
  String get nearbyLocating => 'جارٍ تحديد مكانك…';

  @override
  String get nearbySearching => 'جارٍ البحث عن المساجد…';

  @override
  String nearbyHeaderHere(int km) {
    return 'ضمن $km كم منك';
  }

  @override
  String nearbyHeaderCity(int km, String place) {
    return 'ضمن $km كم من $place';
  }

  @override
  String get nearbyApproximateNote =>
      'شارك هاتفك موقعًا تقريبيًا، لذا قد تبتعد هذه القائمة بضعة كيلومترات. يمكنك السماح بالموقع الدقيق من الإعدادات.';

  @override
  String get nearbyFilterHint => 'تصفية حسب الاسم';

  @override
  String get nearbyUnnamed => 'مسجد بلا اسم';

  @override
  String get nearbyNoAddress => 'لا يوجد عنوان';

  @override
  String get distanceUnder50 => 'أقل من 50 م';

  @override
  String distanceMetres(int metres) {
    return '$metres م';
  }

  @override
  String distanceKilometres(String km) {
    return '$km كم';
  }

  @override
  String get nearbyAttributionGoogle =>
      'النتائج من خرائط Google، وهي غير موثّقة — تحقّق من الاسم قبل الحفظ.';

  @override
  String get nearbyAttributionOsm =>
      'النتائج © مساهمو OpenStreetMap، وهي غير موثّقة — تحقّق من الاسم قبل الحفظ.';

  @override
  String nearbyEmpty(int km) {
    return 'لم يُعثر على مساجد ضمن $km كم. جرّب مدينة، أو أضف مسجدك يدويًا.';
  }

  @override
  String get nearbyNoMatches => 'لا يوجد مسجد في هذه القائمة بهذا الاسم.';

  @override
  String get nearbyAddManually => 'غير موجود؟ أضفه يدويًا';

  @override
  String get nearbyTryOsm => 'ابحث في OpenStreetMap بدلًا من ذلك';

  @override
  String get nearbyFailNoKey =>
      'البحث في خرائط Google غير مُعدّ في هذه النسخة. يمكنك البحث في OpenStreetMap، أو إضافة مسجدك يدويًا.';

  @override
  String get nearbyFailKeyRejected =>
      'رفضت خرائط Google البحث. هذه مشكلة في إعداد التطبيق، لا في هاتفك. يمكنك البحث في OpenStreetMap بدلًا من ذلك.';

  @override
  String get nearbyFailNetwork =>
      'لا يوجد اتصال الآن. مساجدك المحفوظة ومواقيت الصلاة تعمل دون اتصال.';

  @override
  String nearbyFailRateLimited(String provider) {
    return '$provider مشغول. حاول بعد دقيقة، أو أضف مسجدك يدويًا.';
  }

  @override
  String nearbyFailServer(String provider) {
    return 'لم يستجب $provider كما ينبغي. حاول مرة أخرى، أو أضف مسجدك يدويًا.';
  }

  @override
  String get nearbyFailLimit =>
      'انتهى عدد عمليات البحث لهذه الجلسة، لإبقاء التطبيق مجانيًا. يُعاد ضبطه عند فتح التطبيق مجددًا، ولا يزال بإمكانك إضافة مسجد يدويًا.';

  @override
  String get nearbyLocDenied =>
      'لم يُسمح بالموقع. يمكنك البحث حول مدينة بدلًا من ذلك.';

  @override
  String get nearbyLocPermanent =>
      'الموقع متوقف لهذا التطبيق في الإعدادات. اسمح به هناك، أو ابحث حول مدينة.';

  @override
  String get nearbyLocService =>
      'خدمات الموقع متوقفة على هذا الهاتف. شغّلها، أو ابحث حول مدينة.';

  @override
  String get nearbyLocTimeout =>
      'لم يحدد هاتفك موقعه في الوقت المحدد. حاول مرة أخرى، أو ابحث حول مدينة.';

  @override
  String get nearbyLocUnavailable =>
      'تعذّرت قراءة موقعك الآن. ابحث حول مدينة بدلًا من ذلك.';

  @override
  String get tagSaved => 'محفوظ';

  @override
  String get saveMosqueTitle => 'حفظ هذا المسجد';

  @override
  String saveMosqueBody(String provider) {
    return 'تحقّق من الاسم والعنوان — فهما من $provider، لا من المسجد. تبدأ أوقات الإقامة «غير محددة».';
  }

  @override
  String get soundModeFull => 'الأذان كاملًا';

  @override
  String get soundModeShort => 'أذان قصير';

  @override
  String get soundModeStandard => 'الصوت العادي';

  @override
  String get soundModeSilent => 'صامت';

  @override
  String channelAdhan(String sound) {
    return 'الأذان · $sound';
  }

  @override
  String channelNoVibration(String name) {
    return '$name · بلا اهتزاز';
  }

  @override
  String channelAlarmVolume(String name) {
    return '$name · صوت المنبّه';
  }

  @override
  String get channelPreAdhan => 'التذكير قبل الأذان';

  @override
  String channelIqama(String sound) {
    return 'تذكيرات الجماعة · $sound';
  }

  @override
  String notifAdhanTitle(String prayer) {
    return '$prayer';
  }

  @override
  String notifAdhanBody(String prayer) {
    return 'حان الآن موعد أذان $prayer.';
  }

  @override
  String get notifSunriseBody => 'الشمس تشرق الآن. انتهى وقت الفجر.';

  @override
  String notifPreAdhanTitle(String prayer, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$prayer بعد $minutes دقيقة',
      many: '$prayer بعد $minutes دقيقة',
      few: '$prayer بعد $minutes دقائق',
      two: '$prayer بعد دقيقتين',
      one: '$prayer بعد دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get notifPreAdhanBody => 'تذكير قبل الأذان.';

  @override
  String get notifPreSunriseBody => 'ينتهي وقت الفجر عند الشروق.';

  @override
  String get notifIqamaCall => 'حيّ على الصلاة';

  @override
  String notifIqamaBody(String prayer, int minutes, String mosque) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'إقامة $prayer بعد $minutes دقيقة في $mosque.',
      many: 'إقامة $prayer بعد $minutes دقيقة في $mosque.',
      few: 'إقامة $prayer بعد $minutes دقائق في $mosque.',
      two: 'إقامة $prayer بعد دقيقتين في $mosque.',
      one: 'إقامة $prayer بعد دقيقة في $mosque.',
    );
    return '$_temp0';
  }

  @override
  String notifIqamaBodyNoMosque(String prayer, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'إقامة $prayer بعد $minutes دقيقة.',
      many: 'إقامة $prayer بعد $minutes دقيقة.',
      few: 'إقامة $prayer بعد $minutes دقائق.',
      two: 'إقامة $prayer بعد دقيقتين.',
      one: 'إقامة $prayer بعد دقيقة.',
    );
    return '$_temp0';
  }

  @override
  String get scheduledTitle => 'الإشعارات المجدولة';

  @override
  String scheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعار مجدول للأسبوعين القادمين',
      many: '$count إشعارًا مجدولًا للأسبوعين القادمين',
      few: '$count إشعارات مجدولة للأسبوعين القادمين',
      two: 'إشعاران مجدولان للأسبوعين القادمين',
      one: 'إشعار واحد مجدول للأسبوعين القادمين',
      zero: 'لا يوجد شيء مجدول للأسبوعين القادمين',
    );
    return '$_temp0';
  }

  @override
  String get scheduledNothing =>
      'لا يوجد شيء مجدول. فعّل تنبيه أذان، أو تذكير الجماعة في مسجدك.';

  @override
  String get scheduledNotificationsOff =>
      'الإشعارات متوقفة لهذا التطبيق، فلن يظهر شيء. يمكنك السماح بها الآن.';

  @override
  String get scheduledExactOff =>
      'المنبّهات الدقيقة غير مسموح بها، فقد تصل الإشعارات متأخرة بضع دقائق. يمكنك السماح بها من الإعدادات.';

  @override
  String get scheduledAllowNotifications => 'السماح بالإشعارات';

  @override
  String get scheduledAllowExact => 'السماح بالمنبّهات الدقيقة';

  @override
  String get scheduledRescheduleNow => 'إعادة الجدولة الآن';

  @override
  String get scheduledBatteryHint =>
      'توقف بعض الهواتف التذكيرات لتوفير البطارية. إن لم يصل أحدها، فاجعل استخدام البطارية لهذا التطبيق «غير مقيّد» في إعدادات التطبيقات.';

  @override
  String get scheduledOpenAppSettings => 'فتح إعدادات التطبيق';

  @override
  String get kindAdhan => 'الأذان';

  @override
  String get kindPreAdhan => 'تذكير قبل الأذان';

  @override
  String get kindIqama => 'تذكير الجماعة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAdhanSection => 'تنبيهات الأذان';

  @override
  String get settingsDefaultSound => 'الصوت الافتراضي';

  @override
  String get settingsDefaultSoundHint =>
      'يُستخدم لكل صلاة لم يُختر لها صوت خاص.';

  @override
  String get settingsAlertOff => 'متوقف';

  @override
  String settingsAlertOn(String sound) {
    return 'مفعّل · $sound';
  }

  @override
  String settingsAlertReminderOnly(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'تذكير فقط · قبل $minutes دقيقة',
      many: 'تذكير فقط · قبل $minutes دقيقة',
      few: 'تذكير فقط · قبل $minutes دقائق',
      two: 'تذكير فقط · قبل دقيقتين',
      one: 'تذكير فقط · قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String settingsAlertOnWithReminder(String sound, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'مفعّل · $sound · تذكير قبل $minutes دقيقة',
      many: 'مفعّل · $sound · تذكير قبل $minutes دقيقة',
      few: 'مفعّل · $sound · تذكير قبل $minutes دقائق',
      two: 'مفعّل · $sound · تذكير قبل دقيقتين',
      one: 'مفعّل · $sound · تذكير قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get settingsIqamaSection => 'تذكيرات الجماعة';

  @override
  String get settingsIqamaBody =>
      'يأتي تذكير الجماعة قبل وقت الإقامة في مسجدك. أوقات الإقامة وتذكيراتها خاصة بكل مسجد، فتُحدَّد من صفحة المسجد.';

  @override
  String settingsIqamaOpenActive(String mosque) {
    return 'فتح $mosque';
  }

  @override
  String get settingsIqamaNoMosque => 'أضف مسجدًا لتحديد تذكيرات الجماعة.';

  @override
  String get settingsTravelSection => 'السفر';

  @override
  String get settingsNotificationsSection => 'الإشعارات';

  @override
  String alertPageTitle(String prayer) {
    return '$prayer';
  }

  @override
  String get alertAdhanSwitch => 'تنبيه الأذان';

  @override
  String get alertAdhanSwitchHint => 'إشعار عند وقت الأذان.';

  @override
  String get alertSunriseHint =>
      'الشروق ليس صلاة؛ والتنبيه يدل على انتهاء وقت الفجر.';

  @override
  String get alertSoundHeader => 'الصوت';

  @override
  String alertUseDefault(String sound) {
    return 'الافتراضي ($sound)';
  }

  @override
  String get alertSilentHint =>
      'يظهر في إشعاراتك دون صوت. وإيقاف التنبيه أمر مختلف: عندها لا يظهر شيء.';

  @override
  String get alertFullHint =>
      'يُشغّل الأذان كاملًا، بالتسجيل المختار في الإعدادات.';

  @override
  String get alertShortHint =>
      'يُشغّل جزءًا قصيرًا من الأذان، يُختار في الإعدادات.';

  @override
  String get alertStandardHint => 'صوت الإشعارات المعتاد في هاتفك.';

  @override
  String get alertPreview => 'استماع';

  @override
  String get alertStopPreview => 'إيقاف';

  @override
  String get alertVibrate => 'اهتزاز';

  @override
  String get alertRingInSilent => 'التنبيه والهاتف صامت';

  @override
  String get alertRingInSilentHint =>
      'يُشغَّل بصوت المنبّه، فتسمعه والهاتف صامت أو على الاهتزاز. وإن كان وضع «عدم الإزعاج» يمنع المنبّهات فلن يُسمع.';

  @override
  String get alertRingInSilentNeedsSound => 'لا صوت في الوضع الصامت ليرنّ.';

  @override
  String get alertReminderHeader => 'تذكير قبل الأذان';

  @override
  String get alertReminderHint =>
      'تنبيه مستقل، حتى لو كان تنبيه الأذان نفسه متوقفًا.';

  @override
  String get alertReminderNone => 'بدون';

  @override
  String get alertTryIt => 'إرسال إشعار تجريبي';

  @override
  String get alertTrySent => 'أُرسل. تحقّق من إشعاراتك.';

  @override
  String notifTestTitle(String prayer) {
    return '$prayer · تجربة';
  }

  @override
  String get notifTestBody => 'هكذا سيبدو صوت هذا التنبيه.';

  @override
  String get adhanStop => 'إيقاف';

  @override
  String get settingsFullScreen => 'الأذان بملء الشاشة';

  @override
  String get settingsFullScreenHint =>
      'عندما يكون الهاتف غير مستخدم، يملأ الأذان الشاشة مع زر إيقاف كبير. ويوقفه أيضًا زرا الصوت أو قلب الهاتف على وجهه.';

  @override
  String get settingsFullScreenDenied =>
      'هاتفك لا يسمح بالتنبيهات بملء الشاشة لهذا التطبيق، فيظهر الأذان كإشعار عادي.';

  @override
  String get settingsFullScreenAllow => 'السماح بالتنبيهات بملء الشاشة';

  @override
  String get alertStopHint =>
      'أوقفه بأي من زرّي الصوت، أو من الإشعار، أو بقلب الهاتف على وجهه.';

  @override
  String get settingsFollowLocation => 'تتبّع موقعي';

  @override
  String get settingsFollowLocationHint =>
      'أثناء وضع السفر، يتحدّث مكانك إلى حيث أنت عند فتح التطبيق، فتتبعك المواقيت بين المدن والمناطق الزمنية.';

  @override
  String get settingsTravelMode => 'وضع السفر';

  @override
  String get settingsTravelModeHint =>
      'يشغّل خيارات السفر أدناه. ويمكن تبديله أيضًا من الطائرة أعلى التطبيق.';

  @override
  String get travelModeTurnOn => 'تشغيل وضع السفر';

  @override
  String get travelModeTurnOff => 'إيقاف وضع السفر';

  @override
  String get travelModeOnSnack => 'وضع السفر مفعّل';

  @override
  String get travelModeOffSnack => 'وضع السفر متوقف';

  @override
  String get settingsAppearanceSection => 'المظهر';

  @override
  String get settingsFullRecording => 'تسجيل الأذان الكامل';

  @override
  String get recordingsTitle => 'تسجيل الأذان الكامل';

  @override
  String get recordingsBody =>
      'يُشغَّل لكل تنبيه مضبوط على «الأذان كاملًا». ويُختار الأذان القصير بشكل منفصل في الإعدادات.';

  @override
  String get recordingPlay => 'تشغيل';

  @override
  String get recordingStop => 'إيقاف';

  @override
  String recordingPlayLabel(String name) {
    return 'تشغيل $name';
  }

  @override
  String recordingStopLabel(String name) {
    return 'إيقاف $name';
  }

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String latitudeNorth(String degrees) {
    return '$degrees° شمالًا';
  }

  @override
  String latitudeSouth(String degrees) {
    return '$degrees° جنوبًا';
  }

  @override
  String get compassNorth => 'ش';

  @override
  String get compassSouth => 'ج';

  @override
  String recordingLength(String minutes, String seconds) {
    return '$minutes:$seconds';
  }

  @override
  String get themeSystem => 'مثل الهاتف';

  @override
  String get themeLight => 'فاتحة';

  @override
  String get themeDark => 'داكنة';

  @override
  String get followDenied =>
      'لم يُسمح بالموقع، فلا يمكن للتطبيق تتبّعك. لا يزال بإمكانك اختيار مدينة.';

  @override
  String get followUnavailable =>
      'تعذّرت قراءة موقعك الآن، لذا يبقى التتبّع متوقفًا. حاول بعد قليل.';

  @override
  String followingUpdated(String ago) {
    return 'تتبّع موقعك · حُدّث $ago';
  }

  @override
  String followingStale(String ago) {
    return 'تعذّر تحديث موقعك. يُستخدم آخر موقع، من $ago.';
  }

  @override
  String get agoJustNow => 'الآن';

  @override
  String agoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقيقة',
      many: 'قبل $count دقيقة',
      few: 'قبل $count دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String agoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      many: 'قبل $count ساعة',
      few: 'قبل $count ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يوم',
      many: 'قبل $count يومًا',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'قبل يوم',
    );
    return '$_temp0';
  }

  @override
  String get previewCity => 'معاينة مدينة أخرى';

  @override
  String previewTitle(String place) {
    return '$place';
  }

  @override
  String previewNote(String place, String current) {
    return 'مواقيت الصلاة في $place. يبقى مكانك $current.';
  }

  @override
  String get methodAuto => 'تحديد تلقائي';

  @override
  String get methodCustom => 'زوايا مخصصة';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodRegionEgyptian => 'أفريقيا، سوريا، لبنان';

  @override
  String get methodIsna => 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)';

  @override
  String get methodRegionIsna => 'أمريكا الشمالية (الولايات المتحدة وكندا)';

  @override
  String get methodMoonsightingCommittee => 'لجنة رؤية الهلال العالمية';

  @override
  String get methodRegionMoonsightingCommittee =>
      'أجزاء من الولايات المتحدة والمملكة المتحدة';

  @override
  String get methodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get methodRegionMuslimWorldLeague =>
      'أوروبا، الشرق الأقصى، أجزاء من الولايات المتحدة، ودول أخرى';

  @override
  String get methodUmmAlQura => 'جامعة أم القرى، مكة المكرمة';

  @override
  String get methodRegionUmmAlQura => 'شبه الجزيرة العربية';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية، كراتشي';

  @override
  String get methodRegionKarachi =>
      'باكستان، أفغانستان، بنغلاديش، الهند، أجزاء من أوروبا';

  @override
  String get methodJakim => 'إدارة التنمية الإسلامية الماليزية (JAKIM)';

  @override
  String get methodRegionJakim => 'ماليزيا';

  @override
  String get methodSingapore => 'المجلس الإسلامي في سنغافورة (MUIS)';

  @override
  String get methodRegionSingapore => 'سنغافورة';

  @override
  String get methodIndonesia => 'وزارة الشؤون الدينية الإندونيسية (KEMENAG)';

  @override
  String get methodRegionIndonesia => 'إندونيسيا';

  @override
  String get methodTurkiye => 'رئاسة الشؤون الدينية التركية (ديانت)';

  @override
  String get methodRegionTurkiye => 'تركيا';

  @override
  String get methodFrance => 'اتحاد المنظمات الإسلامية في فرنسا (UOIF)';

  @override
  String get methodRegionFrance => 'فرنسا';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodRegionKuwait => 'الكويت';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodRegionQatar => 'قطر';

  @override
  String get methodDubai => 'دبي (الإمارات)';

  @override
  String get methodRegionDubai => 'الإمارات العربية المتحدة';

  @override
  String get methodGulfRegion => 'منطقة الخليج';

  @override
  String get methodRegionGulfRegion => 'البحرين، عُمان';

  @override
  String get methodJordan => 'الأردن';

  @override
  String get methodRegionJordan => 'الأردن';

  @override
  String get methodAlgeria => 'الجزائر';

  @override
  String get methodRegionAlgeria => 'الجزائر';

  @override
  String get methodMorocco => 'المغرب';

  @override
  String get methodRegionMorocco => 'المغرب';

  @override
  String get methodTunisia => 'تونس';

  @override
  String get methodRegionTunisia => 'تونس';

  @override
  String get methodRussia => 'الإدارة الدينية لمسلمي روسيا';

  @override
  String get methodRegionRussia => 'روسيا';

  @override
  String get methodPortugal => 'الجالية الإسلامية في لشبونة';

  @override
  String get methodRegionPortugal => 'البرتغال';

  @override
  String get methodTehran => 'معهد الجيوفيزياء، جامعة طهران';

  @override
  String get methodRegionTehran => 'إيران (الشيعة)';

  @override
  String get methodJafari => 'الشيعة الاثنا عشرية، مؤسسة ليفا، قم';

  @override
  String get methodRegionJafari => 'المجتمعات الشيعية';

  @override
  String get settingsPrayerTimesSection => 'مواقيت الصلاة';

  @override
  String get settingsMethod => 'طريقة الحساب';

  @override
  String get settingsAsr => 'طريقة حساب العصر';

  @override
  String get settingsHighLatitude => 'خطوط العرض العليا';

  @override
  String get settingsAdjustments => 'تعديلات يدوية';

  @override
  String get settingsHijri => 'التاريخ الهجري';

  @override
  String zoneNotePlace(String place, String placeOffset, String phoneOffset) {
    return 'المواقيت بالتوقيت المحلي في $place ($placeOffset)، وساعة هاتفك على $phoneOffset.';
  }

  @override
  String get inFlightTitle => 'على متن الطائرة';

  @override
  String onbStep(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get onbContinue => 'متابعة';

  @override
  String get onbBack => 'رجوع';

  @override
  String get onbNotNow => 'ليس الآن';

  @override
  String get onbStart => 'ابدأ';

  @override
  String get onbWelcomeTagline =>
      'اعرف متى تصلي. اعرف متى تُقام الصلاة في مسجدك. ونبّهك في الوقت.';

  @override
  String get onbWelcomeBody =>
      'تُحسب مواقيت الصلاة على هذا الهاتف. بلا حساب، ولا يُرفع أي شيء عنك.';

  @override
  String get onbLanguage => 'اللغة';

  @override
  String onbPlaceFound(String city) {
    return 'وجدناك قرب $city';
  }

  @override
  String placeNear(String place, String city) {
    return '$place، قرب $city';
  }

  @override
  String onbPlaceDone(String place) {
    return 'مواقيت الصلاة في $place';
  }

  @override
  String get onbMosqueTitle => 'مسجدك';

  @override
  String get onbMosqueBody =>
      'أضف المسجد الذي تصلي فيه عادة، ثم أدخل أوقات الإقامة فيه بنفسك: فالتطبيق لا يخمّنها أبدًا. ويمكنك إضافة مساجد أخرى لاحقًا.';

  @override
  String onbMosqueDone(String mosque) {
    return 'أُضيف: $mosque. أدخل أوقات الإقامة فيه من تبويب المساجد.';
  }

  @override
  String get onbAlertsTitle => 'تنبيهات الصلاة';

  @override
  String get onbAlertsBody =>
      'تنبيه أذان عند كل صلاة، وتذكير الجماعة قبل الإقامة في مسجدك. ويمكنك تغيير كل تنبيه وصوته وتوقيته لاحقًا من الإعدادات.';

  @override
  String get onbAlertsSwitch => 'تنبيه الأذان للصلوات الخمس';

  @override
  String get onbAlertsSwitchHint => 'سيطلب هاتفك السماح بالإشعارات.';

  @override
  String get onbAlertsBattery =>
      'توقف بعض الهواتف التنبيهات لتوفير البطارية. إن لم يصل أحدها، فاجعل استخدام البطارية لهذا التطبيق «غير مقيّد» من إعدادات الهاتف.';

  @override
  String get onbTravelTitle => 'هل تسافر كثيرًا؟';

  @override
  String get onbTravelBody =>
      'يجعل وضع السفر مواقيتك تتبعك بين المدن والمناطق الزمنية دون تغيير ساعة هاتفك. وعلى متن الطائرة يضيف وضع الطيران: مواقيت الصلاة والقبلة من GPS ودون إنترنت.';

  @override
  String get onbTravelSwitch => 'تشغيل وضع السفر';

  @override
  String get onbTravelHint => 'يمكنك تبديله في أي وقت من الطائرة أعلى التطبيق.';

  @override
  String get settingsShowIntro => 'عرض المقدمة مرة أخرى';

  @override
  String get inFlightHelp => 'طريقة العمل';

  @override
  String get inFlightHelpTitle => 'وضع الطيران';

  @override
  String get inFlightHelpIntro =>
      'مواقيت الصلاة والقبلة على متن الطائرة، دون إنترنت ودون تغيير ساعة هاتفك.';

  @override
  String get inFlightHelpStartTitle => 'طريقة التشغيل';

  @override
  String get inFlightHelpStartBody =>
      'شغّل وضع السفر من الطائرة أعلى التطبيق. ثم في شاشة اليوم اضغط «على متن رحلة؟» ثم «تشغيل GPS» واسمح بالموقع الدقيق. اجلس بجانب النافذة إن أمكن: فـGPS في هاتفك يعمل في وضع الطيران، لكنه يحتاج إلى رؤية السماء وقد يستغرق دقيقة أو دقيقتين لتحديد مكانك.';

  @override
  String get inFlightHelpTimesTitle => 'مواقيت الصلاة';

  @override
  String get inFlightHelpTimesBody =>
      '«الآن» و«التالية» لمكان الطائرة في هذه اللحظة، معروضة بساعة هاتفك. في الارتفاع تغرب الشمس متأخرة وتشرق مبكرة مقارنة بالأرض تحتك، لذا يتبع المغرب والشروق الشمس كما تراها من الطائرة. أما الفجر والعشاء فيتبعان طريقة الحساب التي اخترتها.';

  @override
  String get inFlightHelpRouteTitle => 'على مسار الرحلة';

  @override
  String get inFlightHelpRouteBody =>
      'أثناء تحرك الطائرة، يقدّر التطبيق متى تدرك الصلوات التالية إن حافظت الطائرة على اتجاهها وسرعتها. ويتحدّث التقدير مع كل قراءة GPS، فيزداد دقة مع تقدّم الرحلة. باتجاه الشرق تأتي الصلوات أبكر؛ وباتجاه الغرب تكاد الطائرة تجاري الشمس، فقد يبقى الغروب بعيدًا ساعات.';

  @override
  String get inFlightHelpQiblaTitle => 'القبلة على متن الطائرة';

  @override
  String get inFlightHelpQiblaBody =>
      'بوصلة الهاتف غير موثوقة داخل الطائرة، لذا يعتمد السهم على اتجاه سير الطائرة من GPS، ويبيّن كم تبعد القبلة يمينًا أو يسارًا عن مقدّمة الطائرة. وعلى الأرض، أو إن شئت، أدخل الاتجاه الظاهر على خريطة الشاشة أمامك.';

  @override
  String get inFlightHelpAlertsTitle => 'التنبيهات أثناء الرحلة';

  @override
  String get inFlightHelpAlertsBody =>
      'أثناء تحرك الطائرة تتوقف تنبيهاتك المعتادة للمكان الذي غادرته، ومعها تذكيرات الجماعة، ويُنبَّه بدلًا منها للصلاة التالية على المسار مع الإشارة إلى أنها تقديرية، بإعدادات أذان تلك الصلاة نفسها. ينتهي الإيقاف تلقائيًا بعد ٩٠ دقيقة من آخر قراءة GPS، أو عند الضغط على «إنهاء وضع الطيران». وفي المنزل أو عند البوابة لا يتوقف شيء.';

  @override
  String get inFlightHelpTipsTitle => 'معلومات مفيدة';

  @override
  String get inFlightHelpTipsBody =>
      'أبقِ شاشة وضع الطيران مفتوحة لأفضل تحديث؛ فإذا أُطفئت الشاشة طويلًا قد يوقف الهاتف GPS. لا يُرسل أي شيء عن مكانك. أما أحكام الصلاة على متن الطائرة، كالقصر والجمع، فارجع فيها إلى أهل العلم: يكتفي التطبيق بالمواقيت والاتجاه.';

  @override
  String notifInFlightBody(String prayer) {
    return 'حان موعد $prayer، بتقدير مسار الطائرة.';
  }

  @override
  String inFlightAlongRoute(String prayer, String countdown) {
    return 'على هذا المسار: $prayer، $countdown';
  }

  @override
  String inFlightAlongRouteThen(String prayer, String time) {
    return 'ثم $prayer، نحو $time على ساعة هاتفك';
  }

  @override
  String inFlightAboutOnPhone(String time) {
    return 'نحو $time على ساعة هاتفك';
  }

  @override
  String get inFlightAssumesCourse =>
      'على افتراض أن الطائرة تحافظ على اتجاهها وسرعتها؛ ويتحدّث مع كل قراءة GPS.';

  @override
  String inFlightAlertsHeld(String place, String time) {
    return 'تنبيهات $place موقوفة حتى $time، ويُنبَّه بدلًا منها للصلاة التالية على مسار الرحلة.';
  }

  @override
  String get inFlightEnd => 'إنهاء وضع الطيران';

  @override
  String inFlightHeldNote(String time) {
    return 'وضع الطيران: التنبيهات المعتادة موقوفة حتى $time.';
  }

  @override
  String get inFlightCardTitle => 'على متن رحلة؟';

  @override
  String get inFlightCardBody =>
      'مواقيت الصلاة والقبلة على متن الطائرة، من GPS ودون اتصال.';

  @override
  String get inFlightExplainBody =>
      'يستخدم التطبيق GPS في هاتفك، وهو يعمل في وضع الطيران، لمعرفة مكان الطائرة. يحتاج إلى الموقع الدقيق، ويعمل أفضل بجانب النافذة. لا يُرسل أي شيء.';

  @override
  String get inFlightStart => 'تشغيل GPS';

  @override
  String get inFlightWaiting => 'بانتظار GPS… المقعد بجانب النافذة يساعد.';

  @override
  String get inFlightServiceOff =>
      'الموقع متوقف في هذا الهاتف. شغّله لاستخدام GPS على متن الطائرة.';

  @override
  String get inFlightNeedsPrecise =>
      'يحتاج وضع الطيران إلى الموقع الدقيق. حاول مرة أخرى واختر «دقيق».';

  @override
  String get inFlightPermanentlyDenied =>
      'الموقع الدقيق متوقف لهذا التطبيق. يمكنك السماح به من إعدادات التطبيق.';

  @override
  String get inFlightOpenSettings => 'فتح إعدادات التطبيق';

  @override
  String get inFlightTryAgain => 'حاول مرة أخرى';

  @override
  String inFlightAltitudeSpeed(String altitude, String speed) {
    return '$altitude م · $speed كم/س';
  }

  @override
  String inFlightFixAge(String ago) {
    return 'قراءة GPS $ago';
  }

  @override
  String inFlightFixLost(String ago) {
    return 'انقطع GPS. تُعرض آخر قراءة، $ago.';
  }

  @override
  String inFlightNow(String prayer) {
    return 'الآن: $prayer';
  }

  @override
  String get inFlightNoneNow => 'لا صلاة حان وقتها الآن';

  @override
  String inFlightNext(String prayer, String countdown) {
    return 'التالية: $prayer، $countdown';
  }

  @override
  String inFlightOnPhone(String time) {
    return '$time على ساعة هاتفك';
  }

  @override
  String inFlightSunsetLater(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'من هذا الارتفاع تغرب الشمس بعد غروبها على الأرض بـ$minutes دقيقة.',
      many: 'من هذا الارتفاع تغرب الشمس بعد غروبها على الأرض بـ$minutes دقيقة.',
      few: 'من هذا الارتفاع تغرب الشمس بعد غروبها على الأرض بـ$minutes دقائق.',
      two: 'من هذا الارتفاع تغرب الشمس بعد غروبها على الأرض بـدقيقتين.',
      one: 'من هذا الارتفاع تغرب الشمس بعد غروبها على الأرض بـدقيقة.',
    );
    return '$_temp0';
  }

  @override
  String inFlightSunriseEarlier(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'من هذا الارتفاع تشرق الشمس قبل شروقها على الأرض بـ$minutes دقيقة.',
      many: 'من هذا الارتفاع تشرق الشمس قبل شروقها على الأرض بـ$minutes دقيقة.',
      few: 'من هذا الارتفاع تشرق الشمس قبل شروقها على الأرض بـ$minutes دقائق.',
      two: 'من هذا الارتفاع تشرق الشمس قبل شروقها على الأرض بـدقيقتين.',
      one: 'من هذا الارتفاع تشرق الشمس قبل شروقها على الأرض بـدقيقة.',
    );
    return '$_temp0';
  }

  @override
  String get inFlightMovingNote =>
      'المواقيت لمكان الطائرة الآن، وتتغير مع تقدّمها؛ وتبقى هذه الشاشة محدّثة ما دامت مفتوحة.';

  @override
  String get inFlightTimesHeader => 'مواقيت اليوم على متن الطائرة، بساعة هاتفك';

  @override
  String get inFlightQiblaHeader => 'القبلة على متن الطائرة';

  @override
  String inFlightQiblaRight(String degrees) {
    return '$degrees° إلى يمين مقدّمة الطائرة';
  }

  @override
  String inFlightQiblaLeft(String degrees) {
    return '$degrees° إلى يسار مقدّمة الطائرة';
  }

  @override
  String get inFlightQiblaAhead => 'أمامك مباشرة';

  @override
  String get inFlightQiblaBehind => 'خلفك، باتجاه ذيل الطائرة';

  @override
  String inFlightHeadingGps(String degrees) {
    return 'باتجاه سير الطائرة من GPS، $degrees°';
  }

  @override
  String inFlightHeadingManual(String degrees) {
    return 'بالاتجاه الذي أدخلته، $degrees°';
  }

  @override
  String get inFlightNoCourse =>
      'الطائرة لا تتحرك بعد، فلا يوجد اتجاه سير. يمكنك إدخال الاتجاه من خريطة الشاشة أمامك.';

  @override
  String get inFlightEnterHeading => 'إدخال الاتجاه';

  @override
  String get inFlightUseGps => 'استخدام اتجاه GPS';

  @override
  String get inFlightHeadingLabel => 'الاتجاه من خريطة الشاشة أمامك (0–359°)';

  @override
  String get inFlightHeadingError => 'بين 0 و359';

  @override
  String inFlightQiblaBearing(String degrees) {
    return 'اتجاه القبلة $degrees° من الشمال الحقيقي';
  }

  @override
  String get inFlightCompassNote =>
      'بوصلة الهاتف غير موثوقة داخل الطائرة، لذا يُستخدم اتجاه الطائرة بدلًا منها.';

  @override
  String get inFlightDiagramLabel =>
      'الطائرة من الأعلى ومقدّمتها للأعلى. يشير السهم إلى القبلة.';

  @override
  String zoneNoteHere(String placeOffset, String phoneOffset) {
    return 'المواقيت بالتوقيت المحلي حيث أنت ($placeOffset)، وساعة هاتفك على $phoneOffset.';
  }

  @override
  String get hijriAsCalculated => 'كما هو محسوب (أم القرى)';

  @override
  String hijriLater(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'متأخر $days يومًا',
      many: 'متأخر $days يومًا',
      few: 'متأخر $days أيام',
      two: 'متأخر يومين',
      one: 'متأخر يومًا',
    );
    return '$_temp0';
  }

  @override
  String hijriEarlier(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'متقدم $days يومًا',
      many: 'متقدم $days يومًا',
      few: 'متقدم $days أيام',
      two: 'متقدم يومين',
      one: 'متقدم يومًا',
    );
    return '$_temp0';
  }

  @override
  String get hijriAdjustNote =>
      'طابِق التاريخ الذي تعلنه بلدك. تبدأ الكويت وغيرها كل شهر برؤية الهلال، وقد يختلف ذلك عن الحساب بيوم أو يومين. لا تتغير مواقيت الصلاة، إلا أن عشاء رمضان المتأخر في طريقة أم القرى يتبع هذا التاريخ.';

  @override
  String methodAngles(String fajr, String isha) {
    return 'الفجر $fajr° · العشاء $isha°';
  }

  @override
  String methodAnglesInterval(String fajr, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'الفجر $fajr° · العشاء بعد المغرب بـ$minutes دقيقة',
      many: 'الفجر $fajr° · العشاء بعد المغرب بـ$minutes دقيقة',
      few: 'الفجر $fajr° · العشاء بعد المغرب بـ$minutes دقائق',
      two: 'الفجر $fajr° · العشاء بعد المغرب بـدقيقتين',
      one: 'الفجر $fajr° · العشاء بعد المغرب بـدقيقة',
    );
    return '$_temp0';
  }

  @override
  String get methodUmmAlQuraRamadan => 'العشاء بعد المغرب بـ120 دقيقة في رمضان';

  @override
  String get methodMoonsightingNote => 'يعدّل الفجر والعشاء أيضًا حسب الموسم';

  @override
  String methodAutoResolved(String method, String place) {
    return 'يستخدم $method في $place';
  }

  @override
  String get methodAutoNoPlace => 'يختار حسب مكانك بعد تحديده';

  @override
  String get customTitle => 'زوايا مخصصة';

  @override
  String get customFajr => 'زاوية الفجر (°)';

  @override
  String get customIsha => 'زاوية العشاء (°)';

  @override
  String get customIshaByMinutes => 'العشاء بدقائق بعد المغرب';

  @override
  String get customIshaMinutes => 'الدقائق بعد المغرب';

  @override
  String get customAngleError => 'بين 10° و22°';

  @override
  String get customMinutesError => 'بين 1 و180 دقيقة';

  @override
  String get asrStandard => 'الجمهور';

  @override
  String get asrStandardHint => 'الشافعي والمالكي والحنبلي: وقت العصر الأبكر';

  @override
  String get asrHanafi => 'الحنفي';

  @override
  String get asrHanafiHint => 'وقت العصر المتأخر';

  @override
  String get ruleMiddleOfTheNightTitle => 'منتصف الليل';

  @override
  String get ruleSeventhOfTheNightTitle => 'سُبع الليل';

  @override
  String get ruleTwilightAngleTitle => 'زاوية الشفق';

  @override
  String get ruleMiddleOfTheNightHint =>
      'الفجر والعشاء لا يتجاوزان منتصف الليل (الافتراضي)';

  @override
  String get ruleSeventhOfTheNightHint =>
      'الفجر والعشاء ضمن السُّبع الأول والأخير من الليل';

  @override
  String get ruleTwilightAngleHint => 'جزء من الليل يتناسب مع زوايا الطريقة';

  @override
  String get highLatitudeSettingsNote =>
      'تُستخدم فقط حيث تبقى الشمس قريبة من الأفق ليلًا؛ وفي غير ذلك لا تغيّر شيئًا.';

  @override
  String get adjustmentsHint =>
      'دقائق تُضاف إلى الوقت المحسوب أو تُطرح منه، مثلًا لمطابقة التقويم المطبوع في مسجدك.';

  @override
  String adjustmentsMinus(String prayer) {
    return '$prayer: تقديم دقيقة';
  }

  @override
  String adjustmentsPlus(String prayer) {
    return '$prayer: تأخير دقيقة';
  }

  @override
  String adjustmentsValue(int minutes) {
    return '$minutes د';
  }

  @override
  String get adjustmentsNone => 'لا يوجد';

  @override
  String get adjustmentsReset => 'إعادة الكل إلى 0';

  @override
  String get reminderSoundChime => 'نغمة';

  @override
  String get soundHayya => 'حيّ على الصلاة';

  @override
  String get reminderSoundHayyaHint => 'نداء الصلاة من الأذان، نحو 10 ثوانٍ.';

  @override
  String get settingsShortAdhan => 'الأذان القصير';

  @override
  String get shortAdhanNaghshbandi => 'النقشبندي، المطلع';

  @override
  String get shortAdhanNaghshbandiHint => 'أول 8 ثوانٍ من أذان النقشبندي.';

  @override
  String get shortAdhanHayyaHint => '«حيّ على الصلاة» من الأذان، 10 ثوانٍ.';

  @override
  String get settingsReminderSound => 'صوت التذكير';

  @override
  String get reminderSoundChimeHint =>
      'نغمة هادئة من نوتتين، مختلفة عن الأذان وعن التطبيقات الأخرى.';

  @override
  String get reminderSoundStandardHint => 'صوت الإشعارات المعتاد في هاتفك.';

  @override
  String get reminderSoundSilentHint => 'يظهر في إشعاراتك دون صوت.';

  @override
  String get settingsReminderVibrate => 'اهتزاز';

  @override
  String get settingsReminderTest => 'إرسال تذكير تجريبي';

  @override
  String get settingsReminderTestSent => 'أُرسل التذكير التجريبي.';

  @override
  String get settingsPauseAllIqama => 'إيقاف جميع تذكيرات الجماعة مؤقتًا';

  @override
  String get settingsPauseAllIqamaHint =>
      'لا تذكيرات جماعة من أي مسجد حتى توقف هذا الخيار. تبقى أوقات الإقامة محفوظة، ولا تتأثر تنبيهات الأذان.';

  @override
  String get mosquePauseReminders => 'إيقاف تذكيرات هذا المسجد مؤقتًا';

  @override
  String get mosquePauseRemindersHint =>
      'تبقى أوقات الإقامة وإعدادات التذكير محفوظة. ويسري ذلك ما دام هذا مسجدك النشط.';

  @override
  String get mosquePauseAllOn =>
      'جميع تذكيرات الجماعة موقوفة مؤقتًا من الإعدادات.';

  @override
  String get pausedAllNote => 'جميع تذكيرات الجماعة موقوفة مؤقتًا.';

  @override
  String pausedMosqueNote(String mosque) {
    return 'تذكيرات الجماعة في $mosque موقوفة مؤقتًا.';
  }

  @override
  String get tagRemindersPaused => 'التذكيرات موقوفة';

  @override
  String get prayerJumuah => 'الجمعة';

  @override
  String get extraImsak => 'الإمساك';

  @override
  String get extraDuha => 'الضحى';

  @override
  String get extraQiyam => 'الثلث الأخير من الليل';

  @override
  String get notifImsakBody => 'الإمساك: أمسك عن الطعام قبل الفجر.';

  @override
  String get notifDuhaBody => 'دخل وقت صلاة الضحى.';

  @override
  String get notifQiyamBody => 'دخل الثلث الأخير من الليل.';

  @override
  String channelExtra(String sound) {
    return 'أوقات أخرى · $sound';
  }

  @override
  String get kindExtra => 'وقت إضافي';

  @override
  String get settingsExtraTimes => 'أوقات إضافية';

  @override
  String get extraTimesIntro =>
      'أوقات إلى جانب الصلوات الخمس، تُحسب من مواقيت صلاتك. ولا إقامة لها.';

  @override
  String get extraShowOnToday => 'إظهار في صفحة اليوم';

  @override
  String get extraAlert => 'تنبيه';

  @override
  String get extraAlertHint => 'يستخدم صوت تذكير الجماعة.';

  @override
  String extraImsakRule(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'قبل الفجر بـ$minutes دقيقة',
      many: 'قبل الفجر بـ$minutes دقيقة',
      few: 'قبل الفجر بـ$minutes دقائق',
      two: 'قبل الفجر بدقيقتين',
      one: 'قبل الفجر بدقيقة',
      zero: 'عند الفجر',
    );
    return '$_temp0';
  }

  @override
  String extraDuhaRule(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة بعد الشروق',
      many: '$minutes دقيقة بعد الشروق',
      few: '$minutes دقائق بعد الشروق',
      two: 'دقيقتين بعد الشروق',
      one: 'دقيقة بعد الشروق',
    );
    return '$_temp0';
  }

  @override
  String get extraQiyamRule => 'الثلث الأخير من الوقت بين المغرب والفجر.';

  @override
  String get extraNoneShown => 'لا شيء معروض';

  @override
  String get listSeparator => '، ';

  @override
  String get jumuahNotSetNote =>
      'لم يُحدَّد وقت الجمعة · يُعرض وقت إقامة الظهر';

  @override
  String get jumuahRowHint => 'يوم الجمعة بدلًا من الظهر';

  @override
  String get jumuahRowNotSet => 'وقت الجمعة غير محدَّد';

  @override
  String get settingsAdhanRingInSilent => 'الأذان يرنّ والهاتف صامت';

  @override
  String get settingsPreAdhanRingInSilent =>
      'التذكير قبل الأذان يرنّ والهاتف صامت';

  @override
  String get ringInSilentSome =>
      'مفعّل لبعض الصلوات. ويمكن تغييره من صفحة كل صلاة.';

  @override
  String get alertPreAdhanRingInSilent => 'التذكير يرنّ والهاتف صامت';

  @override
  String get onbRingInSilent => 'التنبيه حتى لو كان هاتفي صامتًا';

  @override
  String get onbRingInSilentHint =>
      'للأذان والتذكير قبله وتذكيرات الجماعة، بصوت المنبّه. ويمكنك تغيير كل منها في الإعدادات.';

  @override
  String get iqamaModeAfterAdhan => 'دقائق بعد الأذان';

  @override
  String get iqamaModeFixed => 'وقت ثابت';

  @override
  String get iqamaMinutesLabel => 'عدد الدقائق بعد الأذان';

  @override
  String iqamaAfterAdhanPreview(String adhan, int minutes, String iqama) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'الأذان $adhan + $minutes دقيقة = الإقامة $iqama اليوم',
      many: 'الأذان $adhan + $minutes دقيقة = الإقامة $iqama اليوم',
      few: 'الأذان $adhan + $minutes دقائق = الإقامة $iqama اليوم',
      two: 'الأذان $adhan + دقيقتين = الإقامة $iqama اليوم',
      one: 'الأذان $adhan + دقيقة = الإقامة $iqama اليوم',
    );
    return '$_temp0';
  }

  @override
  String get iqamaMinutesInvalid => 'أدخل من 1 إلى 90 دقيقة';

  @override
  String get iqamaNeedsAdhan => 'حدّد موقعك لترى وقت اليوم.';

  @override
  String rowAfterAdhan(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة بعد الأذان',
      many: '$minutes دقيقة بعد الأذان',
      few: '$minutes دقائق بعد الأذان',
      two: 'دقيقتين بعد الأذان',
      one: 'دقيقة بعد الأذان',
    );
    return '$_temp0';
  }

  @override
  String get enterAllFive => 'إدخال الدقائق للصلوات الخمس';

  @override
  String get enterAllFiveTitle => 'الإقامة: الدقائق بعد الأذان';

  @override
  String get enterAllFiveHint =>
      'كما يعلنها مسجدك، مثل الفجر 22. وتبقى الحقول الفارغة على حالها.';

  @override
  String iqamaAfterAdhanPreviewTomorrow(
    String adhan,
    int minutes,
    String iqama,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'الأذان $adhan + $minutes دقيقة = الإقامة $iqama غدًا',
      many: 'الأذان $adhan + $minutes دقيقة = الإقامة $iqama غدًا',
      few: 'الأذان $adhan + $minutes دقائق = الإقامة $iqama غدًا',
      two: 'الأذان $adhan + دقيقتين = الإقامة $iqama غدًا',
      one: 'الأذان $adhan + دقيقة = الإقامة $iqama غدًا',
    );
    return '$_temp0';
  }

  @override
  String get reminderSoundCustom => 'صوتك الخاص';

  @override
  String get reminderSoundCustomHint => 'ملف من هاتفك. يُشغَّل حتى 30 ثانية.';

  @override
  String reminderSoundCustomNamed(String name) {
    return 'صوتك: $name';
  }

  @override
  String get recordingsYours => 'تسجيلاتك';

  @override
  String get soundAddFromPhone => 'إضافة من هاتفك';

  @override
  String get soundRename => 'إعادة التسمية';

  @override
  String get soundDelete => 'حذف';

  @override
  String get soundName => 'الاسم';

  @override
  String soundDeleteConfirm(String name) {
    return 'حذف «$name»؟ ما يستخدمه يعود إلى الصوت المدمج.';
  }

  @override
  String get soundCouldNotAdd => 'تعذّرت إضافة هذا الملف.';

  @override
  String soundOptions(String name) {
    return 'خيارات $name';
  }

  @override
  String get prayerRecording => 'التسجيل';

  @override
  String prayerRecordingSame(String name) {
    return 'كما في الإعدادات ($name)';
  }

  @override
  String get prayerRecordingHint =>
      'يُشغَّل عندما يكون صوت هذه الصلاة الأذان الكامل.';

  @override
  String recordingsForPrayer(String prayer) {
    return 'تسجيل $prayer';
  }
}
