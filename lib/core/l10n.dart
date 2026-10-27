import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'text_utils.dart';

/// Lightweight localization: Persian (default for Persian devices) and English.
///
/// Strings are looked up by key with English as fallback, so a missing
/// translation degrades gracefully instead of crashing.
class L10n {
  const L10n(this.lang);

  final String lang;

  static const supportedLocales = [Locale('fa'), Locale('en')];
  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  static L10n of(BuildContext context) =>
      Localizations.of<L10n>(context, L10n) ?? const L10n('en');

  bool get isFa => lang == 'fa';

  String t(String key) => (isFa ? _fa[key] : null) ?? _en[key] ?? key;

  /// [t] with `{name}` placeholders replaced. Numbers get localized digits.
  String f(String key, Map<String, Object> args) {
    var s = t(key);
    args.forEach((name, value) {
      s = s.replaceAll('{$name}', value is num ? n(value) : '$value');
    });
    return s;
  }

  /// A number with localized digits.
  String n(num value) => localizeDigits('$value', lang);

  @visibleForTesting
  static Set<String> get englishKeys => _en.keys.toSet();

  @visibleForTesting
  static Set<String> get persianKeys => _fa.keys.toSet();
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  bool isSupported(Locale locale) => const ['fa', 'en'].contains(locale.languageCode);

  @override
  Future<L10n> load(Locale locale) => SynchronousFuture(L10n(locale.languageCode));

  @override
  bool shouldReload(covariant LocalizationsDelegate<L10n> old) => false;
}

extension L10nContext on BuildContext {
  L10n get l10n => L10n.of(this);
}

const Map<String, String> _en = {
  // general
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'undo': 'Undo',
  'ok': 'OK',
  'add': 'Add',
  'clear': 'Clear',
  'close': 'Close',
  'merge': 'Merge',
  'replace': 'Replace',
  'today': 'Today',
  'tomorrow': 'Tomorrow',
  'yesterday': 'Yesterday',

  // onboarding
  'obWelcomeTitle': 'Welcome to MindDrop',
  'obTagline': 'Catch every thought before it slips away.',
  'obChooseLanguage': 'Choose your language',
  'obChooseTheme': 'Pick your look',
  'obThemeHint': 'You can change this any time in settings.',
  'obAccent': 'Accent color',
  'obReadyTitle': "You're all set",
  'obFeature1Title': 'Capture in a second',
  'obFeature1Body': 'Type, hit enter, done. Use #tags and ! for priority.',
  'obFeature2Title': 'Never forget',
  'obFeature2Body': 'Set a reminder and get notified right on time.',
  'obFeature3Title': 'Find anything',
  'obFeature3Body': 'Instant search across titles, notes and tags.',
  'obFeature4Title': 'Yours, offline',
  'obFeature4Body': 'Everything stays on your phone. Export a backup to move it anywhere.',
  'next': 'Next',
  'back': 'Back',
  'getStarted': "Let's go",

  // themes
  'themeDark': 'Dark',
  'themeLight': 'Light',
  'themeSystem': 'System',

  // home
  'greetingMorning': 'Good morning',
  'greetingAfternoon': 'Good afternoon',
  'greetingEvening': 'Good evening',
  'greetingNight': 'Good night',
  'tabInbox': 'All',
  'tabToday': 'Today',
  'tabUpcoming': 'Upcoming',
  'tabDone': 'Done',
  'fabNew': 'New drop',
  'summaryToday': '{count} due today',
  'summaryOverdue': '{count} overdue',
  'summaryActive': '{count} open tasks',
  'summaryClear': 'Nothing due today. Enjoy! ✨',
  'todayProgress': '{done} of {total} done today',
  'allTags': 'All',
  'secPinned': 'Pinned',
  'secOverdue': 'Overdue',
  'secToday': 'Today',
  'secUpcoming': 'Upcoming',
  'secSomeday': 'No date',
  'secCompleted': 'Completed',
  'emptyInboxTitle': 'Your mind is clear',
  'emptyInboxBody': 'Tap + whenever something pops into your head.',
  'emptyTodayTitle': 'Nothing for today',
  'emptyTodayBody': 'Tasks due today show up here.',
  'emptyUpcomingTitle': 'No upcoming tasks',
  'emptyUpcomingBody': 'Give tasks a date to plan ahead.',
  'emptyDoneTitle': 'Nothing done yet',
  'emptyDoneBody': 'Completed tasks are kept here.',
  'clearCompleted': 'Clear completed',
  'clearCompletedConfirm': 'Delete {count} completed tasks?',
  'taskDeleted': 'Task deleted',
  'tasksDeleted': '{count} tasks deleted',
  'taskCompleted': 'Nice! Task done ✓',
  'pin': 'Pin',
  'unpin': 'Unpin',
  'markDone': 'Mark as done',
  'markUndone': 'Mark as not done',
  'duplicate': 'Duplicate',
  'duplicated': 'Copy created',
  'swipeDone': 'Done',
  'swipeUndo': 'Not done',
  'swipeDelete': 'Delete',
  'search': 'Search',
  'settings': 'Settings',
  'stats': 'Statistics',

  // quick add
  'quickHint': "What's on your mind?",
  'quickTips': '#tag  ·  ! !! !!! priority  ·  today / tomorrow',
  'dueToday': 'Today',
  'dueTomorrow': 'Tomorrow',
  'dueNextWeek': 'Next week',
  'pickDate': 'Pick a date…',
  'noDate': 'No date',
  'saveAndNew': 'Save & add another',
  'savedCount': '{count} saved',
  'openEditor': 'More details',
  'setReminder': 'Remind me',
  'priority': 'Priority',
  'prioNone': 'None',
  'prioLow': 'Low',
  'prioMedium': 'Medium',
  'prioHigh': 'High',

  // editor
  'newTask': 'New task',
  'editTask': 'Edit task',
  'titleHint': 'Task title',
  'noteHint': 'Add notes…',
  'schedule': 'Schedule',
  'dueDate': 'Date',
  'dueTime': 'Time',
  'noTime': 'Any time',
  'reminder': 'Reminder',
  'reminderAt': 'At {time}',
  'reminderNeedsDate': 'Set a date first',
  'tags': 'Tags',
  'addTag': 'Add tag',
  'tagHint': 'Tag name',
  'subtasks': 'Subtasks',
  'addSubtask': 'Add a step',
  'createdAt': 'Created {date}',
  'completedOn': 'Completed {date}',
  'deleteConfirmTitle': 'Delete this task?',
  'titleRequired': 'Give it a title first',

  // search
  'searchHint': 'Search tasks, notes, #tags',
  'filterAll': 'All',
  'filterActive': 'Open',
  'filterDone': 'Done',
  'noResults': 'No matching tasks',
  'noResultsBody': 'Try other words or fewer filters.',
  'searchIdle': 'Type to search',
  'searchIdleBody': 'Search looks through titles, notes, subtasks and tags.',
  'resultsCount': '{count} results',

  // settings
  'appearance': 'Appearance',
  'theme': 'Theme',
  'amoled': 'Pure black',
  'amoledDesc': 'Saves battery on OLED screens',
  'accent': 'Accent color',
  'language': 'Language',
  'calendar': 'Calendar',
  'calJalali': 'Solar Hijri',
  'calGregorian': 'Gregorian',
  'behavior': 'Behavior',
  'showCompleted': 'Show completed in "All"',
  'smartParse': 'Smart capture',
  'smartParseDesc': 'Detect #tags, ! priority and today/tomorrow while typing',
  'haptics': 'Haptic feedback',
  'reminderTime': 'Default reminder time',
  'reminderTimeDesc': 'Used when a task has a date but no time',
  'notifications': 'Notifications',
  'notifEnabled': 'Notifications are on',
  'notifDisabled': 'Notifications are off — tap to allow',
  'notifDenied': 'Permission denied. Enable notifications for MindDrop in system settings.',
  'data': 'Backup & data',
  'exportFile': 'Export to file',
  'exportFileDesc': 'Save a backup you can import on any phone',
  'shareBackup': 'Share backup',
  'shareBackupDesc': 'Send it to Telegram, Drive, email…',
  'importFile': 'Import from file',
  'importFileDesc': 'Restore tasks from a MindDrop backup',
  'exportDone': 'Backup saved ✓',
  'exportFailed': "Couldn't save the file",
  'importTitle': 'Import backup',
  'importSummary': 'This backup contains {count} tasks.',
  'importExported': 'Exported {date}',
  'importHow':
      'Merge keeps your current tasks and adds the new ones. Replace deletes everything first.',
  'importDone': '{added} added, {updated} updated',
  'importNotJson': "This file isn't a valid backup.",
  'importNotMindDrop': "This file isn't a MindDrop backup.",
  'importNewer': 'This backup is from a newer version. Update MindDrop first.',
  'importFailed': "Couldn't read the file",
  'importEmpty': 'The backup has no tasks',
  'deleteAll': 'Delete all tasks',
  'deleteAllConfirm':
      'This permanently deletes all {count} tasks. Export a backup first if you might need them.',
  'allDeleted': 'All tasks deleted',
  'about': 'About',
  'version': 'Version {v}',
  'aboutBody': 'Open source · MIT license\nMade with 💜',
  'taskCount': '{count} tasks stored on this device',

  // stats
  'statActive': 'Open',
  'statDone': 'Completed',
  'statOverdue': 'Overdue',
  'statStreak': 'Day streak',
  'last7': 'Last 7 days',
  'completionRate': 'Completion rate',
  'topTags': 'Top tags',
  'noTagsYet': 'No tags yet',
  'streakStart': 'Complete a task to start a streak 🔥',
  'streakKeep': 'Keep it going! 🔥',

  // notifications
  'notifChannel': 'Reminders',
  'notifChannelDesc': 'Task reminders',
  'notifBody': 'Reminder from MindDrop',

  // sample tasks created after onboarding
  'sample1Title': '👋 Welcome! Tap me to see the details',
  'sample1Note':
      'This is a task. Add notes, subtasks, tags, a date and a reminder — everything saves automatically.',
  'sample1Sub1': 'Open a task',
  'sample1Sub2': 'Tick a subtask',
  'sample1Sub3': 'Export a backup from settings',
  'sample2Title': '👉 Swipe right to complete, left to delete',
  'sample3Title': 'Type #tags and !!! while capturing',
  'sample3Tag': 'ideas',
  'sample4Title': '📌 Long-press a task for more options',
};

const Map<String, String> _fa = {
  // general
  'save': 'ذخیره',
  'cancel': 'انصراف',
  'delete': 'حذف',
  'undo': 'برگردون',
  'ok': 'باشه',
  'add': 'افزودن',
  'clear': 'پاک کردن',
  'close': 'بستن',
  'merge': 'ادغام',
  'replace': 'جایگزینی',
  'today': 'امروز',
  'tomorrow': 'فردا',
  'yesterday': 'دیروز',

  // onboarding
  'obWelcomeTitle': 'به MindDrop خوش اومدی',
  'obTagline': 'هر فکری که به ذهنت رسید، قبل از اینکه از دستش بدی ثبتش کن.',
  'obChooseLanguage': 'زبان رو انتخاب کن',
  'obChooseTheme': 'ظاهر رو انتخاب کن',
  'obThemeHint': 'هر وقت خواستی از تنظیمات عوضش کن.',
  'obAccent': 'رنگ اصلی',
  'obReadyTitle': 'همه‌چیز آماده‌ست',
  'obFeature1Title': 'ثبت در یک ثانیه',
  'obFeature1Body': 'بنویس، Enter بزن، تمام. با # برچسب بزن و با ! اولویت بده.',
  'obFeature2Title': 'هیچ‌وقت یادت نمی‌ره',
  'obFeature2Body': 'یادآور بذار تا سر وقت خبرت کنیم.',
  'obFeature3Title': 'همه‌چیز رو پیدا کن',
  'obFeature3Body': 'جستجوی آنی توی عنوان، یادداشت و برچسب‌ها.',
  'obFeature4Title': 'مال خودت، آفلاین',
  'obFeature4Body': 'همه‌چیز روی گوشی خودت می‌مونه. با خروجی پشتیبان هر جا خواستی منتقلش کن.',
  'next': 'بعدی',
  'back': 'قبلی',
  'getStarted': 'بزن بریم',

  // themes
  'themeDark': 'تیره',
  'themeLight': 'روشن',
  'themeSystem': 'خودکار',

  // home
  'greetingMorning': 'صبح بخیر',
  'greetingAfternoon': 'روز بخیر',
  'greetingEvening': 'عصر بخیر',
  'greetingNight': 'شب بخیر',
  'tabInbox': 'همه',
  'tabToday': 'امروز',
  'tabUpcoming': 'پیش رو',
  'tabDone': 'انجام‌شده',
  'fabNew': 'کار جدید',
  'summaryToday': '{count} کار برای امروز',
  'summaryOverdue': '{count} عقب‌افتاده',
  'summaryActive': '{count} کار باز',
  'summaryClear': 'امروز کاری نداری. خوش بگذره! ✨',
  'todayProgress': 'امروز {done} از {total} انجام شد',
  'allTags': 'همه',
  'secPinned': 'سنجاق‌شده',
  'secOverdue': 'عقب‌افتاده',
  'secToday': 'امروز',
  'secUpcoming': 'پیش رو',
  'secSomeday': 'بدون تاریخ',
  'secCompleted': 'انجام‌شده',
  'emptyInboxTitle': 'ذهنت آزاده',
  'emptyInboxBody': 'هر وقت چیزی یادت افتاد، دکمه + رو بزن.',
  'emptyTodayTitle': 'امروز کاری نداری',
  'emptyTodayBody': 'کارهایی که موعدشون امروزه اینجا میان.',
  'emptyUpcomingTitle': 'کار پیش رویی نداری',
  'emptyUpcomingBody': 'برای برنامه‌ریزی، به کارها تاریخ بده.',
  'emptyDoneTitle': 'هنوز کاری انجام نشده',
  'emptyDoneBody': 'کارهای انجام‌شده اینجا نگه داشته می‌شن.',
  'clearCompleted': 'پاک کردن انجام‌شده‌ها',
  'clearCompletedConfirm': '{count} کار انجام‌شده حذف بشه؟',
  'taskDeleted': 'کار حذف شد',
  'tasksDeleted': '{count} کار حذف شد',
  'taskCompleted': 'آفرین! انجام شد ✓',
  'pin': 'سنجاق کردن',
  'unpin': 'برداشتن سنجاق',
  'markDone': 'انجام شد',
  'markUndone': 'برگرداندن به کارهای باز',
  'duplicate': 'کپی',
  'duplicated': 'کپی ساخته شد',
  'swipeDone': 'انجام',
  'swipeUndo': 'برگشت',
  'swipeDelete': 'حذف',
  'search': 'جستجو',
  'settings': 'تنظیمات',
  'stats': 'آمار',

  // quick add
  'quickHint': 'چی تو ذهنته؟',
  'quickTips': '#برچسب  ·  ! !! !!! اولویت  ·  امروز / فردا',
  'dueToday': 'امروز',
  'dueTomorrow': 'فردا',
  'dueNextWeek': 'هفته بعد',
  'pickDate': 'انتخاب تاریخ…',
  'noDate': 'بدون تاریخ',
  'saveAndNew': 'ذخیره و بعدی',
  'savedCount': '{count} مورد ذخیره شد',
  'openEditor': 'جزئیات بیشتر',
  'setReminder': 'یادآوری',
  'priority': 'اولویت',
  'prioNone': 'بدون',
  'prioLow': 'کم',
  'prioMedium': 'متوسط',
  'prioHigh': 'زیاد',

  // editor
  'newTask': 'کار جدید',
  'editTask': 'ویرایش کار',
  'titleHint': 'عنوان کار',
  'noteHint': 'یادداشت…',
  'schedule': 'زمان‌بندی',
  'dueDate': 'تاریخ',
  'dueTime': 'ساعت',
  'noTime': 'هر ساعتی',
  'reminder': 'یادآور',
  'reminderAt': 'ساعت {time}',
  'reminderNeedsDate': 'اول تاریخ رو مشخص کن',
  'tags': 'برچسب‌ها',
  'addTag': 'افزودن برچسب',
  'tagHint': 'نام برچسب',
  'subtasks': 'زیرکارها',
  'addSubtask': 'افزودن مرحله',
  'createdAt': 'ساخته‌شده: {date}',
  'completedOn': 'انجام‌شده: {date}',
  'deleteConfirmTitle': 'این کار حذف بشه؟',
  'titleRequired': 'اول یه عنوان بنویس',

  // search
  'searchHint': 'جستجو در کارها، یادداشت‌ها، #برچسب‌ها',
  'filterAll': 'همه',
  'filterActive': 'باز',
  'filterDone': 'انجام‌شده',
  'noResults': 'چیزی پیدا نشد',
  'noResultsBody': 'کلمه دیگه‌ای امتحان کن یا فیلترها رو کم کن.',
  'searchIdle': 'برای جستجو تایپ کن',
  'searchIdleBody': 'جستجو توی عنوان، یادداشت، زیرکارها و برچسب‌ها انجام می‌شه.',
  'resultsCount': '{count} نتیجه',

  // settings
  'appearance': 'ظاهر',
  'theme': 'تم',
  'amoled': 'مشکی کامل (AMOLED)',
  'amoledDesc': 'روی صفحه‌های OLED باتری کمتری مصرف می‌کنه',
  'accent': 'رنگ اصلی',
  'language': 'زبان',
  'calendar': 'تقویم',
  'calJalali': 'شمسی',
  'calGregorian': 'میلادی',
  'behavior': 'رفتار',
  'showCompleted': 'نمایش انجام‌شده‌ها در «همه»',
  'smartParse': 'ثبت هوشمند',
  'smartParseDesc': 'تشخیص #برچسب، ! اولویت و امروز/فردا هنگام تایپ',
  'haptics': 'لرزش هنگام لمس',
  'reminderTime': 'ساعت پیش‌فرض یادآوری',
  'reminderTimeDesc': 'برای کارهایی که تاریخ دارن ولی ساعت ندارن',
  'notifications': 'اعلان‌ها',
  'notifEnabled': 'اعلان‌ها فعاله',
  'notifDisabled': 'اعلان‌ها خاموشه — برای فعال‌سازی بزن',
  'notifDenied': 'دسترسی داده نشد. از تنظیمات گوشی اعلان MindDrop رو روشن کن.',
  'data': 'پشتیبان‌گیری و داده‌ها',
  'exportFile': 'خروجی گرفتن در فایل',
  'exportFileDesc': 'یه فایل پشتیبان بساز که روی هر گوشی‌ای وارد بشه',
  'shareBackup': 'ارسال فایل پشتیبان',
  'shareBackupDesc': 'بفرست به تلگرام، درایو، ایمیل و…',
  'importFile': 'وارد کردن از فایل',
  'importFileDesc': 'بازیابی کارها از فایل پشتیبان MindDrop',
  'exportDone': 'فایل پشتیبان ذخیره شد ✓',
  'exportFailed': 'ذخیره فایل انجام نشد',
  'importTitle': 'وارد کردن پشتیبان',
  'importSummary': 'این فایل {count} کار داره.',
  'importExported': 'تاریخ خروجی: {date}',
  'importHow':
      '«ادغام» کارهای فعلی رو نگه می‌داره و جدیدها رو اضافه می‌کنه. «جایگزینی» اول همه‌چیز رو پاک می‌کنه.',
  'importDone': '{added} کار اضافه و {updated} کار به‌روز شد',
  'importNotJson': 'این فایل پشتیبان معتبر نیست.',
  'importNotMindDrop': 'این فایل مربوط به MindDrop نیست.',
  'importNewer': 'این پشتیبان از نسخه جدیدتری اومده. اول اپ رو آپدیت کن.',
  'importFailed': 'خوندن فایل انجام نشد',
  'importEmpty': 'فایل هیچ کاری نداره',
  'deleteAll': 'حذف همه کارها',
  'deleteAllConfirm':
      'همه {count} کار برای همیشه پاک می‌شن. اگه ممکنه لازمشون داشته باشی، اول خروجی بگیر.',
  'allDeleted': 'همه کارها حذف شدن',
  'about': 'درباره',
  'version': 'نسخه {v}',
  'aboutBody': 'متن‌باز · مجوز MIT\nساخته‌شده با 💜',
  'taskCount': '{count} کار روی این گوشی ذخیره شده',

  // stats
  'statActive': 'باز',
  'statDone': 'انجام‌شده',
  'statOverdue': 'عقب‌افتاده',
  'statStreak': 'روز پیاپی',
  'last7': '۷ روز اخیر',
  'completionRate': 'نرخ انجام',
  'topTags': 'برچسب‌های پرکاربرد',
  'noTagsYet': 'هنوز برچسبی نداری',
  'streakStart': 'یه کار انجام بده تا زنجیره شروع بشه 🔥',
  'streakKeep': 'ادامه بده! 🔥',

  // notifications
  'notifChannel': 'یادآورها',
  'notifChannelDesc': 'یادآوری کارها',
  'notifBody': 'یادآوری از MindDrop',

  // sample tasks created after onboarding
  'sample1Title': '👋 خوش اومدی! روی من بزن تا جزئیات رو ببینی',
  'sample1Note':
      'این یه کاره. می‌تونی یادداشت، زیرکار، برچسب، تاریخ و یادآور بهش اضافه کنی — همه‌چیز خودکار ذخیره می‌شه.',
  'sample1Sub1': 'یه کار رو باز کن',
  'sample1Sub2': 'یه زیرکار رو تیک بزن',
  'sample1Sub3': 'از تنظیمات یه خروجی پشتیبان بگیر',
  'sample2Title': '👈 به چپ بکش = انجام، به راست بکش = حذف',
  'sample3Title': 'موقع نوشتن با # برچسب بزن و با !!! اولویت بده',
  'sample3Tag': 'ایده',
  'sample4Title': '📌 روی یه کار انگشتت رو نگه دار تا گزینه‌های بیشتر بیاد',
};
