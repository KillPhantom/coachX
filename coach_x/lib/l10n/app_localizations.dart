import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Unit preference setting
  ///
  /// In en, this message translates to:
  /// **'Unit Preference'**
  String get unitPreference;

  /// Metric unit system
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get metric;

  /// Imperial unit system
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get imperial;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Chinese language name
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language selection page title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Account settings option
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// Help center option
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// Log out option
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Subscription section title
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Personal information section
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Age label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// Height label
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// Weight label
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Coach information section
  ///
  /// In en, this message translates to:
  /// **'Coach Info'**
  String get coachInfo;

  /// Student role
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// Generic error message title
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Alert dialog title
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// Feature under development message
  ///
  /// In en, this message translates to:
  /// **'This feature is under development'**
  String get featureInDevelopment;

  /// Avatar edit feature message
  ///
  /// In en, this message translates to:
  /// **'Avatar editing is under development'**
  String get avatarEditInDevelopment;

  /// Account settings feature message
  ///
  /// In en, this message translates to:
  /// **'Account Settings is under development'**
  String get accountSettingsInDevelopment;

  /// Help center feature message
  ///
  /// In en, this message translates to:
  /// **'Help Center is under development'**
  String get helpCenterInDevelopment;

  /// Unit preference selection title
  ///
  /// In en, this message translates to:
  /// **'Select Unit Preference'**
  String get selectUnitPreference;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Copy action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Close action
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// All items filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Search action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Acknowledgment button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get know;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Students tab label
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// Plans tab label
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get tabPlans;

  /// Chat tab label
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// Plan tab label (student)
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'CoachX'**
  String get appName;

  /// Application tagline
  ///
  /// In en, this message translates to:
  /// **'AI Coaching Platform'**
  String get appTagline;

  /// Email input placeholder
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailPlaceholder;

  /// Password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordPlaceholder;

  /// Password required error
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get passwordRequired;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No account prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Sign up link
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpNow;

  /// Get user info failed error
  ///
  /// In en, this message translates to:
  /// **'Failed to get user info'**
  String get getUserInfoFailed;

  /// Get user info timeout error
  ///
  /// In en, this message translates to:
  /// **'Get user info timeout, please try again'**
  String get getUserInfoTimeout;

  /// Login failed error
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Create account title
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// Registration subtitle
  ///
  /// In en, this message translates to:
  /// **'Start your fitness journey'**
  String get startYourJourney;

  /// Name input placeholder
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get namePlaceholder;

  /// Name required error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// Password minimum length label
  ///
  /// In en, this message translates to:
  /// **'Password (at least 6 characters)'**
  String get passwordMinLength;

  /// Confirm password placeholder
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordPlaceholder;

  /// Confirm password required error
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get confirmPasswordRequired;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordMismatch;

  /// Terms agreement text
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms of Service and Privacy Policy'**
  String get termsAgreement;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Has account prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get hasAccount;

  /// Login now link
  ///
  /// In en, this message translates to:
  /// **'Login now'**
  String get loginNow;

  /// Forgot password feature message
  ///
  /// In en, this message translates to:
  /// **'Forgot password feature is under development'**
  String get forgotPasswordInDevelopment;

  /// Registration failed error
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerFailed;

  /// Coach home summary section title
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get coachHomeSummaryTitle;

  /// Students completed training today message
  ///
  /// In en, this message translates to:
  /// **'{count} students completed training today'**
  String studentsCompletedTrainingToday(int count);

  /// Unread messages count
  ///
  /// In en, this message translates to:
  /// **'{count} unread messages'**
  String unreadMessagesCount(int count);

  /// Unreviewed trainings count
  ///
  /// In en, this message translates to:
  /// **'{count} training records need to be reviewed'**
  String unreviewedTrainingsCount(int count);

  /// Event reminder section title
  ///
  /// In en, this message translates to:
  /// **'Event Reminder'**
  String get eventReminderTitle;

  /// No upcoming events message
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get noUpcomingEvents;

  /// Recent activity section title
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivityTitle;

  /// No recent activity message
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// Search student placeholder
  ///
  /// In en, this message translates to:
  /// **'Search by student name'**
  String get searchStudentPlaceholder;

  /// Student count display
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String studentCount(int count);

  /// No students found message
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get noStudentsFound;

  /// No students message
  ///
  /// In en, this message translates to:
  /// **'No students'**
  String get noStudents;

  /// Try adjust filters tip
  ///
  /// In en, this message translates to:
  /// **'Try adjusting filters'**
  String get tryAdjustFilters;

  /// Invite students tip
  ///
  /// In en, this message translates to:
  /// **'Tap the add button to invite students'**
  String get inviteStudentsTip;

  /// Clear filters action
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Invite students action
  ///
  /// In en, this message translates to:
  /// **'Invite students'**
  String get inviteStudents;

  /// Student details title
  ///
  /// In en, this message translates to:
  /// **'Student Details'**
  String get studentDetails;

  /// Student deleted success message
  ///
  /// In en, this message translates to:
  /// **'Student deleted'**
  String get studentDeleted;

  /// Delete failed error
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// Confirm delete student message
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete student \"{name}\"? This action cannot be undone.'**
  String confirmDeleteStudent(String name);

  /// Filter options title
  ///
  /// In en, this message translates to:
  /// **'Filter options'**
  String get filterOptions;

  /// No training plans message
  ///
  /// In en, this message translates to:
  /// **'No training plans'**
  String get noTrainingPlans;

  /// Filter by training plan label
  ///
  /// In en, this message translates to:
  /// **'Filter by training plan'**
  String get filterByTrainingPlan;

  /// Invitation code management title
  ///
  /// In en, this message translates to:
  /// **'Invitation Code Management'**
  String get invitationCodeManagement;

  /// Invitation code description
  ///
  /// In en, this message translates to:
  /// **'Generate invitation codes for student registration'**
  String get invitationCodeDescription;

  /// Contract duration label
  ///
  /// In en, this message translates to:
  /// **'Contract duration (days)'**
  String get contractDurationDays;

  /// Example days placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g., 180'**
  String get exampleDays;

  /// Remark optional label
  ///
  /// In en, this message translates to:
  /// **'Remark (optional)'**
  String get remarkOptional;

  /// Remark example placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g., VIP exclusive'**
  String get remarkExample;

  /// Existing invitation codes title
  ///
  /// In en, this message translates to:
  /// **'Existing invitation codes'**
  String get existingInvitationCodes;

  /// No invitation codes message
  ///
  /// In en, this message translates to:
  /// **'No invitation codes'**
  String get noInvitationCodes;

  /// Load failed error
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get loadFailed;

  /// Generate invitation code action
  ///
  /// In en, this message translates to:
  /// **'Generate invitation code'**
  String get generateInvitationCode;

  /// Please enter contract duration error
  ///
  /// In en, this message translates to:
  /// **'Please enter contract duration'**
  String get pleaseEnterContractDuration;

  /// Contract duration range error
  ///
  /// In en, this message translates to:
  /// **'Contract duration must be between 1 and 365 days'**
  String get contractDurationRangeError;

  /// Generate failed error
  ///
  /// In en, this message translates to:
  /// **'Generate failed'**
  String get generateFailed;

  /// Invitation code generated success
  ///
  /// In en, this message translates to:
  /// **'Invitation code generated successfully'**
  String get invitationCodeGenerated;

  /// Invitation code copied message
  ///
  /// In en, this message translates to:
  /// **'Invitation code copied'**
  String get invitationCodeCopied;

  /// Select action title
  ///
  /// In en, this message translates to:
  /// **'Select action'**
  String get selectAction;

  /// View details action
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// Assign plan action
  ///
  /// In en, this message translates to:
  /// **'Assign plan'**
  String get assignPlan;

  /// Delete student action
  ///
  /// In en, this message translates to:
  /// **'Delete student'**
  String get deleteStudent;

  /// Confirm delete title
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// Plans page title
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plansTitle;

  /// Training tab label
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get tabTraining;

  /// Diet tab label
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get tabDiet;

  /// Supplements tab label
  ///
  /// In en, this message translates to:
  /// **'Supplements'**
  String get tabSupplements;

  /// Copy plan action
  ///
  /// In en, this message translates to:
  /// **'Copy plan'**
  String get copyPlan;

  /// Confirm copy plan message
  ///
  /// In en, this message translates to:
  /// **'Are you sure to copy \"{planName}\"?'**
  String confirmCopyPlan(String planName);

  /// Delete plan action
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get deletePlan;

  /// Confirm delete plan message
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete \"{planName}\"? This action cannot be undone.'**
  String confirmDeletePlan(String planName);

  /// Copy success message
  ///
  /// In en, this message translates to:
  /// **'Copy successful'**
  String get copySuccess;

  /// Copy failed error
  ///
  /// In en, this message translates to:
  /// **'Copy failed'**
  String get copyFailed;

  /// Delete success message
  ///
  /// In en, this message translates to:
  /// **'Delete successful'**
  String get deleteSuccess;

  /// Refresh failed error
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshFailed;

  /// No results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No plans found for query message
  ///
  /// In en, this message translates to:
  /// **'No plans found for \"{query}\"'**
  String noPlansFoundForQuery(String query);

  /// Clear search action
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No plans yet message
  ///
  /// In en, this message translates to:
  /// **'No plans yet'**
  String get noPlansYet;

  /// Create first plan message
  ///
  /// In en, this message translates to:
  /// **'Create your first {planType} plan'**
  String createFirstPlan(String planType);

  /// Create plan action
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get createPlan;

  /// Create new plan title
  ///
  /// In en, this message translates to:
  /// **'Create New Plan'**
  String get createNewPlanTitle;

  /// Create plan subtitle
  ///
  /// In en, this message translates to:
  /// **'What would you like to create today?'**
  String get createPlanSubtitle;

  /// Exercise plan title
  ///
  /// In en, this message translates to:
  /// **'Exercise Plan'**
  String get exercisePlanTitle;

  /// Exercise plan description
  ///
  /// In en, this message translates to:
  /// **'Create training schedules and workout routines'**
  String get exercisePlanDesc;

  /// Diet plan title
  ///
  /// In en, this message translates to:
  /// **'Diet Plan'**
  String get dietPlanTitle;

  /// Diet plan description
  ///
  /// In en, this message translates to:
  /// **'Design meal plans and nutrition guidelines'**
  String get dietPlanDesc;

  /// Supplement plan title
  ///
  /// In en, this message translates to:
  /// **'Supplement Plan'**
  String get supplementPlanTitle;

  /// Supplement plan description
  ///
  /// In en, this message translates to:
  /// **'Plan supplement schedules and dosages'**
  String get supplementPlanDesc;

  /// Assign to student action
  ///
  /// In en, this message translates to:
  /// **'Assign to student'**
  String get assignToStudent;

  /// Imperial unit display
  ///
  /// In en, this message translates to:
  /// **'Imperial (ft, lbs)'**
  String get imperialUnit;

  /// Metric unit display
  ///
  /// In en, this message translates to:
  /// **'Metric (cm, kg)'**
  String get metricUnit;

  /// Update failed error
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// Confirm log out title
  ///
  /// In en, this message translates to:
  /// **'Confirm log out'**
  String get confirmLogOut;

  /// Confirm log out message
  ///
  /// In en, this message translates to:
  /// **'Are you sure to log out?'**
  String get confirmLogOutMessage;

  /// Add record title
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecordTitle;

  /// Choose record type message
  ///
  /// In en, this message translates to:
  /// **'Choose a record type to add'**
  String get chooseRecordType;

  /// Training record type
  ///
  /// In en, this message translates to:
  /// **'Training Record'**
  String get trainingRecord;

  /// Diet record type
  ///
  /// In en, this message translates to:
  /// **'Diet Record'**
  String get dietRecord;

  /// Supplement record type
  ///
  /// In en, this message translates to:
  /// **'Supplement Record'**
  String get supplementRecord;

  /// Body measurement type
  ///
  /// In en, this message translates to:
  /// **'Body Measurement'**
  String get bodyMeasurement;

  /// Student home title
  ///
  /// In en, this message translates to:
  /// **'Student Home'**
  String get studentHome;

  /// To be implemented message
  ///
  /// In en, this message translates to:
  /// **'To be implemented'**
  String get toBeImplemented;

  /// Training page title
  ///
  /// In en, this message translates to:
  /// **'Training Page'**
  String get trainingPageTitle;

  /// No coach info message
  ///
  /// In en, this message translates to:
  /// **'No coach info'**
  String get noCoachInfo;

  /// Load coach info failed error
  ///
  /// In en, this message translates to:
  /// **'Failed to load coach info'**
  String get loadCoachInfoFailed;

  /// Privacy settings option
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// Messages page title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No students message for coach
  ///
  /// In en, this message translates to:
  /// **'No students yet, please add students first'**
  String get noStudentsMessage;

  /// No conversations message
  ///
  /// In en, this message translates to:
  /// **'No conversations'**
  String get noConversations;

  /// No coach or conversations message for student
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a coach or conversations yet'**
  String get noCoachOrConversations;

  /// Conversation title
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversationTitle;

  /// Chat tab label in detail page
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTabLabel;

  /// Feedback tab label
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTabLabel;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messageInputPlaceholder;

  /// Send failed error
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailed;

  /// User not logged in error
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// Error view title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// Supplement timing note label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get supplementTimingNote;

  /// Supplement timing note input placeholder
  ///
  /// In en, this message translates to:
  /// **'Add note...'**
  String get supplementTimingNotePlaceholder;

  /// Weekly training status section title
  ///
  /// In en, this message translates to:
  /// **'Weekly Status'**
  String get weeklyStatus;

  /// Days recorded count
  ///
  /// In en, this message translates to:
  /// **'{count} of 7 days recorded'**
  String daysRecorded(int count);

  /// Today's record section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Record'**
  String get todayRecord;

  /// Exercise record label
  ///
  /// In en, this message translates to:
  /// **'Exercise Record'**
  String get exerciseRecord;

  /// Protein macro label
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// Carbs macro label
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// Fat macro label
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// Calories label
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// Meals count
  ///
  /// In en, this message translates to:
  /// **'{count} meals'**
  String mealsCount(int count);

  /// Exercises count
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String exercisesCount(int count);

  /// Supplements count
  ///
  /// In en, this message translates to:
  /// **'{count} supplements'**
  String supplementsCount(int count);

  /// Today's training name
  ///
  /// In en, this message translates to:
  /// **'Today: {name}'**
  String todayTraining(String name);

  /// Rest day label
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get restDay;

  /// No plan assigned message
  ///
  /// In en, this message translates to:
  /// **'No Plan Assigned'**
  String get noPlanAssigned;

  /// Contact coach for plan message
  ///
  /// In en, this message translates to:
  /// **'Contact your coach to get a training plan'**
  String get contactCoachForPlan;

  /// View available plans button
  ///
  /// In en, this message translates to:
  /// **'View Available Plans'**
  String get viewAvailablePlans;

  /// Detail button label
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// Day number label
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayNumber(int day);

  /// Days per week label
  ///
  /// In en, this message translates to:
  /// **'{days} days/week'**
  String daysPerWeek(int days);

  /// No exercises message
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercises;

  /// Assign plans to student dialog title
  ///
  /// In en, this message translates to:
  /// **'Assign Plans to'**
  String get assignPlansToStudent;

  /// Exercise plan section header
  ///
  /// In en, this message translates to:
  /// **'Training Plan'**
  String get exercisePlanSection;

  /// Diet plan section header
  ///
  /// In en, this message translates to:
  /// **'Diet Plan'**
  String get dietPlanSection;

  /// Supplement plan section header
  ///
  /// In en, this message translates to:
  /// **'Supplement Plan'**
  String get supplementPlanSection;

  /// Option to remove plan assignment
  ///
  /// In en, this message translates to:
  /// **'No Plan (Remove Assignment)'**
  String get noPlanOption;

  /// Current plan indicator
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentPlan;

  /// Loading plans message
  ///
  /// In en, this message translates to:
  /// **'Loading plans...'**
  String get loadingPlans;

  /// No plans available message
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get noPlansAvailable;

  /// Assignment saved success message
  ///
  /// In en, this message translates to:
  /// **'Plans assigned successfully'**
  String get assignmentSaved;

  /// Assignment failed error message
  ///
  /// In en, this message translates to:
  /// **'Assignment failed'**
  String get assignmentFailed;

  /// Not assigned status
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get notAssigned;

  /// Done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
