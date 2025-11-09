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

  /// Retry button
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

  /// Load failed error title
  ///
  /// In en, this message translates to:
  /// **'Load Failed'**
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

  /// Confirm delete dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record?'**
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
  /// **'Record Your Activity'**
  String get addRecordTitle;

  /// Add record subtitle
  ///
  /// In en, this message translates to:
  /// **'What would you like to add today?'**
  String get addRecordSubtitle;

  /// Choose record type message
  ///
  /// In en, this message translates to:
  /// **'Choose a record type to add'**
  String get chooseRecordType;

  /// Training record page title
  ///
  /// In en, this message translates to:
  /// **'Training Record'**
  String get trainingRecord;

  /// Training record description
  ///
  /// In en, this message translates to:
  /// **'Log sets, reps, weight, and videos.'**
  String get trainingRecordDesc;

  /// Diet record type
  ///
  /// In en, this message translates to:
  /// **'Record Meal'**
  String get dietRecord;

  /// Today's meal plan title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meal Plan'**
  String get todayMealPlan;

  /// Diet record description
  ///
  /// In en, this message translates to:
  /// **'Log food, quantity, and photos.'**
  String get dietRecordDesc;

  /// Supplement record type
  ///
  /// In en, this message translates to:
  /// **'Supplement Record'**
  String get supplementRecord;

  /// Supplement plan title
  ///
  /// In en, this message translates to:
  /// **'Supplement Plan'**
  String get supplementPlan;

  /// Supplements count with action label
  ///
  /// In en, this message translates to:
  /// **'{count} supplements to take'**
  String supplementsToTake(int count);

  /// Body measurement type
  ///
  /// In en, this message translates to:
  /// **'Record Body Stats'**
  String get bodyMeasurement;

  /// Body measurement description
  ///
  /// In en, this message translates to:
  /// **'Log weight and upload body pictures.'**
  String get bodyMeasurementDesc;

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

  /// Today's meal plan section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meal Plan'**
  String get todayRecord;

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

  /// Total nutrition section title
  ///
  /// In en, this message translates to:
  /// **'Total Nutrition'**
  String get totalNutrition;

  /// Kilocalories unit
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

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

  /// No exercises placeholder title
  ///
  /// In en, this message translates to:
  /// **'No Exercises'**
  String get noExercises;

  /// Sets unit
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get sets;

  /// Reps unit
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get reps;

  /// Exercise sets format with weight
  ///
  /// In en, this message translates to:
  /// **'{sets} sets x {reps} reps @ {weight}'**
  String exerciseSetsWithWeight(int sets, String reps, String weight);

  /// Exercise sets format without weight
  ///
  /// In en, this message translates to:
  /// **'{sets} sets x {reps} reps'**
  String exerciseSetsNoWeight(int sets, String reps);

  /// Exercise sets only
  ///
  /// In en, this message translates to:
  /// **'{sets} sets'**
  String exerciseSetsOnly(int sets);

  /// Video label
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// Coach notes label
  ///
  /// In en, this message translates to:
  /// **'Coach Notes:'**
  String get coachNotes;

  /// AI guidance feature placeholder message
  ///
  /// In en, this message translates to:
  /// **'AI Guidance Feature Coming Soon'**
  String get aiGuidanceInDevelopment;

  /// Coming soon dialog title
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

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

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No coach assigned title
  ///
  /// In en, this message translates to:
  /// **'No Coach Assigned'**
  String get noCoachTitle;

  /// No coach assigned message
  ///
  /// In en, this message translates to:
  /// **'Please contact support to get a coach assigned'**
  String get noCoachMessage;

  /// Plan tab training label
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get planTabTraining;

  /// Plan tab diet label
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get planTabDiet;

  /// Plan tab supplements label
  ///
  /// In en, this message translates to:
  /// **'Supplements'**
  String get planTabSupplements;

  /// Coach's plan header
  ///
  /// In en, this message translates to:
  /// **'Coach\'s Plan'**
  String get coachsPlan;

  /// Coach note label
  ///
  /// In en, this message translates to:
  /// **'Coach Note'**
  String get coachNote;

  /// Kilogram unit
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// Pounds unit
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get lbs;

  /// No exercises for body part message
  ///
  /// In en, this message translates to:
  /// **'No exercises for this body part'**
  String get noExercisesForBodyPart;

  /// Meal record page title
  ///
  /// In en, this message translates to:
  /// **'Meal Record'**
  String get mealRecord;

  /// Coach suggestion section title
  ///
  /// In en, this message translates to:
  /// **'Coach Suggestion'**
  String get coachSuggestion;

  /// Total macros label
  ///
  /// In en, this message translates to:
  /// **'Total Macros'**
  String get totalMacros;

  /// Add record button label
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecord;

  /// Edit record action
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get editRecord;

  /// Take picture button label
  ///
  /// In en, this message translates to:
  /// **'Take Picture'**
  String get takePicture;

  /// Upload image button label
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// Comments section label
  ///
  /// In en, this message translates to:
  /// **'Comments or Questions'**
  String get commentsOrQuestions;

  /// Save meal record button label
  ///
  /// In en, this message translates to:
  /// **'Save Meal Record'**
  String get saveMealRecord;

  /// Comments placeholder text
  ///
  /// In en, this message translates to:
  /// **'Type your message here...'**
  String get typeYourMessageHere;

  /// Meal completed status label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get mealCompleted;

  /// Mark as complete button label
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get markAsComplete;

  /// Edit meal button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMeal;

  /// Record saved success message
  ///
  /// In en, this message translates to:
  /// **'Record saved successfully'**
  String get recordSaved;

  /// Record save failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to save record'**
  String get recordSaveFailed;

  /// No meals planned message
  ///
  /// In en, this message translates to:
  /// **'No meals planned for today'**
  String get noMealsToday;

  /// Macros format string
  ///
  /// In en, this message translates to:
  /// **'{protein}P/{carbs}C/{fat}F'**
  String macrosFormat(int protein, int carbs, int fat);

  /// AI food scanner page title
  ///
  /// In en, this message translates to:
  /// **'AI Food Scanner'**
  String get aiFoodScanner;

  /// Scan food button label
  ///
  /// In en, this message translates to:
  /// **'Scan Food'**
  String get scanFood;

  /// Upload photo button label
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// Analyzing progress message
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// Camera focus area hint text
  ///
  /// In en, this message translates to:
  /// **'Position food within the frame'**
  String get positionFoodInFrame;

  /// Food analysis results title
  ///
  /// In en, this message translates to:
  /// **'Analysis Results'**
  String get foodAnalysisResults;

  /// Estimated weight label
  ///
  /// In en, this message translates to:
  /// **'Estimated Weight'**
  String get estimatedWeight;

  /// Adjust values hint
  ///
  /// In en, this message translates to:
  /// **'Adjust values if needed'**
  String get adjustValues;

  /// Select meal label
  ///
  /// In en, this message translates to:
  /// **'Select Meal'**
  String get selectMeal;

  /// Save to meal button
  ///
  /// In en, this message translates to:
  /// **'Save to Meal'**
  String get saveToMeal;

  /// Number of recognized foods
  ///
  /// In en, this message translates to:
  /// **'{count} foods recognized'**
  String recognizedFoods(int count);

  /// Camera permission denied message
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Please enable camera access in Settings.'**
  String get cameraPermissionDenied;

  /// Analysis failed title
  ///
  /// In en, this message translates to:
  /// **'Analysis Failed'**
  String get analysisFailed;

  /// Planned nutrition label
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get plannedNutrition;

  /// Meal progress label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get mealProgress;

  /// AI detected foods label
  ///
  /// In en, this message translates to:
  /// **'Detected Foods'**
  String get aiDetectedFoods;

  /// Calories input label
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesInput;

  /// Protein input label
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinInput;

  /// Carbs input label
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbsInput;

  /// Fat input label
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatInput;

  /// AI detect button label
  ///
  /// In en, this message translates to:
  /// **'AI Smart Detection'**
  String get aiDetectButton;

  /// Add food record title
  ///
  /// In en, this message translates to:
  /// **'Add Food Record'**
  String get addFoodRecord;

  /// Select meal placeholder
  ///
  /// In en, this message translates to:
  /// **'Select meal to analyze'**
  String get selectMealToAnalyze;

  /// Record saved success message
  ///
  /// In en, this message translates to:
  /// **'Food record saved successfully'**
  String get recordSavedSuccess;

  /// AI scanner mode label
  ///
  /// In en, this message translates to:
  /// **'AI Scanner'**
  String get aiScannerMode;

  /// Simple record mode label
  ///
  /// In en, this message translates to:
  /// **'Simple Record'**
  String get simpleRecordMode;

  /// AI analyzing message
  ///
  /// In en, this message translates to:
  /// **'AI analyzing your food...'**
  String get aiAnalyzing;

  /// AI analysis progress label
  ///
  /// In en, this message translates to:
  /// **'Analysis Progress'**
  String get aiAnalysisProgress;

  /// Select meal to save prompt
  ///
  /// In en, this message translates to:
  /// **'Select meal to save'**
  String get selectMealToSave;

  /// Body stats history page title
  ///
  /// In en, this message translates to:
  /// **'Body Stats History'**
  String get bodyStatsHistory;

  /// Record body stats action
  ///
  /// In en, this message translates to:
  /// **'Record Body Stats'**
  String get recordBodyStats;

  /// Body fat percentage label
  ///
  /// In en, this message translates to:
  /// **'Body Fat %'**
  String get bodyFat;

  /// Body fat percentage optional field
  ///
  /// In en, this message translates to:
  /// **'Body Fat % (Optional)'**
  String get bodyFatOptional;

  /// Skip photo button
  ///
  /// In en, this message translates to:
  /// **'Skip Photo'**
  String get skipPhoto;

  /// Enter weight placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter Weight'**
  String get enterWeight;

  /// Enter body fat percentage placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter Body Fat %'**
  String get enterBodyFat;

  /// Last 14 days filter
  ///
  /// In en, this message translates to:
  /// **'Last 14 Days'**
  String get last14Days;

  /// Last 30 days filter
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// Last 90 days filter
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get last90Days;

  /// Delete record action
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// Empty state message for body stats
  ///
  /// In en, this message translates to:
  /// **'No body stats data yet'**
  String get noBodyStatsData;

  /// Weight trend chart title
  ///
  /// In en, this message translates to:
  /// **'Weight Trend'**
  String get weightTrend;

  /// Record deleted success message
  ///
  /// In en, this message translates to:
  /// **'Record deleted successfully'**
  String get recordDeleted;

  /// Record updated success message
  ///
  /// In en, this message translates to:
  /// **'Record updated successfully'**
  String get recordUpdated;

  /// Maximum photos limit message
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 photos allowed'**
  String get maxPhotosReached;

  /// History section label
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Photos label
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// Take photo action
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// My recordings section title
  ///
  /// In en, this message translates to:
  /// **'My Recordings'**
  String get myRecordings;

  /// Record video button label
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get recordVideo;

  /// Training set label
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// Quick complete button label
  ///
  /// In en, this message translates to:
  /// **'Quick Complete'**
  String get quickComplete;

  /// Completed status label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Video duration exceeded error message
  ///
  /// In en, this message translates to:
  /// **'Video must be ≤ 1 minute'**
  String get videoDurationExceeded;

  /// Recording video status
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recordingVideo;

  /// Select from gallery action
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGallery;

  /// Start timer dialog title
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get startTimerConfirmTitle;

  /// Start timer confirmation message
  ///
  /// In en, this message translates to:
  /// **'Start training timer?'**
  String get startTimerConfirmMessage;

  /// Start timer button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTimerButton;

  /// Weight input placeholder
  ///
  /// In en, this message translates to:
  /// **'Bodyweight/60kg'**
  String get weightPlaceholder;

  /// Time spent label for exercise
  ///
  /// In en, this message translates to:
  /// **'Time Spent'**
  String get timeSpentLabel;

  /// Add custom exercise hint
  ///
  /// In en, this message translates to:
  /// **'Tap \'+\' to add custom exercise'**
  String get addCustomExerciseHint;

  /// Number of completed exercises
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String completedCount(int count);

  /// Current exercise label in timer
  ///
  /// In en, this message translates to:
  /// **'Current Exercise'**
  String get currentExercise;

  /// Total duration label in timer
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get totalDuration;

  /// Congratulations title when all exercises are completed
  ///
  /// In en, this message translates to:
  /// **'Congrats!'**
  String get congratsTitle;

  /// Congratulations message when all exercises are completed
  ///
  /// In en, this message translates to:
  /// **'You have finished all the exercises today!'**
  String get congratsMessage;

  /// Compact congratulations message for single-line display
  ///
  /// In en, this message translates to:
  /// **'Congrats! All exercises done!'**
  String get congratsMessageCompact;

  /// Button text to create a new plan
  ///
  /// In en, this message translates to:
  /// **'Create New Plan'**
  String get createNewPlan;

  /// Dropdown header to select a plan
  ///
  /// In en, this message translates to:
  /// **'Select Plan'**
  String get selectPlan;

  /// Section label for user's own plans
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get myPlans;

  /// Label for coach-assigned plans
  ///
  /// In en, this message translates to:
  /// **'Coach\'s Plan'**
  String get coachPlan;
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
