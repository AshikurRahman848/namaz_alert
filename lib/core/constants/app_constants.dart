class AppConstants {
  // Prayer API
  static const prayerApiBase = 'https://api.aladhan.com/v1';
  static const hadithApiBase = 'https://api.hadith.gading.dev';

  // Default location (Dhaka, Bangladesh)
  static const defaultCity = 'Dhaka';
  static const defaultCountry = 'Bangladesh';
  static const defaultMethod = 1; // University of Islamic Sciences, Karachi

  // Notification
  static const defaultOffsetMinutes = 10;

  // Storage keys
  static const keyUser = 'user';
  static const keyGroups = 'groups';
  static const keyPrayerTimes = 'prayer_times';
  static const keyLastPrayerFetch = 'last_prayer_fetch';
  static const keyNotificationOffset = 'notification_offset';
  static const keyOnboarded = 'onboarded';
  static const keyFcmToken = 'fcm_token';

  // Namaz names
  static const namazNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  // Notification channels
  static const namazChannelId = 'namaz_channel';
  static const namazChannelName = 'Namaz Notifications';
  static const hadithChannelId = 'hadith_channel';
  static const hadithChannelName = 'Hadith Notifications';
}
