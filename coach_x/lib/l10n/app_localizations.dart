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

  /// Weight stat label
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

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Cancel button
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

  /// Error dialog title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Copy action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Close button text
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
  /// **'{count} to be reviewed'**
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

  /// Error message when loading fails
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

  /// Button text to view meal details
  ///
  /// In en, this message translates to:
  /// **'View Details'**
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

  /// Confirm delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
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

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No results found'**
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

  /// Start recording button label
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// View records button label
  ///
  /// In en, this message translates to:
  /// **'View Records'**
  String get viewRecords;

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

  /// Weight change stat card title
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightChange;

  /// Calories intake stat card title
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesIntake;

  /// Volume PR stat card title
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumePR;

  /// Empty state message for stat cards
  ///
  /// In en, this message translates to:
  /// **'No data yet, start recording now'**
  String get noDataStartRecording;

  /// Label shown when only previous week data is available
  ///
  /// In en, this message translates to:
  /// **'Last week\'s data'**
  String get lastWeekData;

  /// Today's meal plan section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meal Plan'**
  String get todayRecord;

  /// Protein nutrition label
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// Carbohydrates nutrition label
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

  /// Calories nutrition label
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

  /// Sets label (plural)
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

  /// Video label with number (e.g., Video 1, Video 2)
  ///
  /// In en, this message translates to:
  /// **'Video {number}'**
  String videoWithNumber(int number);

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

  /// OK button text
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

  /// Save button
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

  /// Take picture button
  ///
  /// In en, this message translates to:
  /// **'Take Picture'**
  String get takePicture;

  /// Upload image button
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

  /// Camera permission denied error
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
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

  /// Use photo button
  ///
  /// In en, this message translates to:
  /// **'Use Photo'**
  String get usePhoto;

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

  /// Record exists dialog title
  ///
  /// In en, this message translates to:
  /// **'Record Already Exists'**
  String get recordExistsTitle;

  /// Record exists dialog message
  ///
  /// In en, this message translates to:
  /// **'You already have a record for {date}. Do you want to replace it?'**
  String recordExistsMessage(String date);

  /// Replace button text
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

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

  /// Record video button
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

  /// Video duration validation error
  ///
  /// In en, this message translates to:
  /// **'Video duration exceeds 60 seconds'**
  String get videoDurationExceeded;

  /// Recording video status
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recordingVideo;

  /// Select video from gallery button
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// Video duration exceeds limit error title
  ///
  /// In en, this message translates to:
  /// **'Video too long'**
  String get videoTooLong;

  /// Video duration exceeds limit error message
  ///
  /// In en, this message translates to:
  /// **'Please select a video under 60 seconds'**
  String get videoTooLongMessage;

  /// Video processing failed error
  ///
  /// In en, this message translates to:
  /// **'Video processing failed'**
  String get videoProcessingFailed;

  /// Video compression failed warning
  ///
  /// In en, this message translates to:
  /// **'Video compression failed, uploading original file'**
  String get videoCompressionFailed;

  /// Photo library permission denied error
  ///
  /// In en, this message translates to:
  /// **'Photo library permission denied'**
  String get photoLibraryPermissionDenied;

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

  /// Placeholder text for feedback search bar
  ///
  /// In en, this message translates to:
  /// **'Search feedback...'**
  String get feedbackSearchPlaceholder;

  /// Label for start date filter
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get feedbackStartDate;

  /// Label for end date filter
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get feedbackEndDate;

  /// Label for today's feedback group
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get feedbackToday;

  /// Label for yesterday's feedback group
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get feedbackYesterday;

  /// Message shown when there is no feedback
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get feedbackNoFeedback;

  /// Description shown when there is no feedback
  ///
  /// In en, this message translates to:
  /// **'Training feedback will appear here'**
  String get feedbackNoFeedbackDesc;

  /// Error message when feedback fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedback'**
  String get feedbackLoadError;

  /// Button text to retry loading feedback
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get feedbackRetry;

  /// Training reviews page title
  ///
  /// In en, this message translates to:
  /// **'Training Reviews'**
  String get trainingReviews;

  /// Search placeholder for student name
  ///
  /// In en, this message translates to:
  /// **'Search by student name'**
  String get searchStudentName;

  /// Filter button for all records
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter button for pending records
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// Filter button for reviewed records
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get filterReviewed;

  /// Pending status badge label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Reviewed status badge label
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get statusReviewed;

  /// Empty state title for training reviews
  ///
  /// In en, this message translates to:
  /// **'No training reviews'**
  String get noTrainingReviews;

  /// Empty state description for training reviews
  ///
  /// In en, this message translates to:
  /// **'Training records will appear here'**
  String get noTrainingReviewsDesc;

  /// Today's summary section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Summary'**
  String get todaySummary;

  /// Nutrition details modal title
  ///
  /// In en, this message translates to:
  /// **'Nutrition Details'**
  String get nutritionDetails;

  /// Exercise video section title
  ///
  /// In en, this message translates to:
  /// **'Exercise Record Video'**
  String get exerciseRecordVideo;

  /// Keyframes section title
  ///
  /// In en, this message translates to:
  /// **'Keyframes'**
  String get keyframes;

  /// Message shown while keyframes are being extracted
  ///
  /// In en, this message translates to:
  /// **'Keyframes extracting...'**
  String get keyframesProcessing;

  /// Message when no keyframes exist
  ///
  /// In en, this message translates to:
  /// **'No keyframes available'**
  String get noKeyframes;

  /// Action to view a keyframe in fullscreen
  ///
  /// In en, this message translates to:
  /// **'View Keyframe'**
  String get viewKeyframe;

  /// Fats nutrition label
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get fats;

  /// Feedback input placeholder
  ///
  /// In en, this message translates to:
  /// **'Add feedback for this set...'**
  String get addFeedback;

  /// Complete button label
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Empty nutrition data message
  ///
  /// In en, this message translates to:
  /// **'No nutrition data'**
  String get noNutritionData;

  /// Empty exercise records message
  ///
  /// In en, this message translates to:
  /// **'No exercise records'**
  String get noExerciseRecords;

  /// Saving feedback loading message
  ///
  /// In en, this message translates to:
  /// **'Saving feedback...'**
  String get savingFeedback;

  /// Feedback saved success message
  ///
  /// In en, this message translates to:
  /// **'Feedback saved successfully'**
  String get feedbackSaved;

  /// Failed to save feedback error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save feedback'**
  String get failedToSave;

  /// No data found error message
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// Details button text
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Training details dialog title
  ///
  /// In en, this message translates to:
  /// **'Training Details'**
  String get trainingDetails;

  /// Video upload progress text
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get videoUploading;

  /// Video upload error message
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get videoUploadFailed;

  /// Retry upload button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryUpload;

  /// Processing indicator text
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Video player page title
  ///
  /// In en, this message translates to:
  /// **'Video Player'**
  String get videoPlayer;

  /// Video load failed error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get videoLoadFailed;

  /// Exercise library section title
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get exerciseLibrary;

  /// Placeholder for exercise search input
  ///
  /// In en, this message translates to:
  /// **'Search Exercises'**
  String get searchExercises;

  /// Exercises count label
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get exercises;

  /// New exercise button
  ///
  /// In en, this message translates to:
  /// **'New Exercise'**
  String get newExercise;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get noExercisesYet;

  /// Empty state call to action
  ///
  /// In en, this message translates to:
  /// **'Create your first exercise template'**
  String get createFirstExercise;

  /// Tags label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// Delete exercise dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Exercise'**
  String get deleteExercise;

  /// Delete exercise confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this exercise?'**
  String get confirmDeleteExercise;

  /// Add tag dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// Tag name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter tag name'**
  String get tagNameHint;

  /// Duplicate tag error message
  ///
  /// In en, this message translates to:
  /// **'Tag already exists'**
  String get tagAlreadyExists;

  /// Button text to extract video keyframes
  ///
  /// In en, this message translates to:
  /// **'Extract Keyframes'**
  String get extractKeyframes;

  /// Loading text during keyframe extraction
  ///
  /// In en, this message translates to:
  /// **'Extracting keyframes...'**
  String get extractingKeyframes;

  /// Create exercise sheet title
  ///
  /// In en, this message translates to:
  /// **'Create Exercise'**
  String get createExercise;

  /// Edit exercise sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit Exercise'**
  String get editExercise;

  /// Exercise name label
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseName;

  /// Exercise name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter exercise name'**
  String get exerciseNameHint;

  /// Select tags label
  ///
  /// In en, this message translates to:
  /// **'Select Tags'**
  String get selectTags;

  /// Tag validation error
  ///
  /// In en, this message translates to:
  /// **'Please select at least one tag'**
  String get atLeastOneTag;

  /// Label for guidance video section
  ///
  /// In en, this message translates to:
  /// **'Guidance Video'**
  String get guidanceVideo;

  /// Delete video button
  ///
  /// In en, this message translates to:
  /// **'Delete Video'**
  String get deleteVideo;

  /// Label for text guidance section
  ///
  /// In en, this message translates to:
  /// **'Text Guidance'**
  String get textGuidance;

  /// Text guidance input hint
  ///
  /// In en, this message translates to:
  /// **'Enter detailed guidance'**
  String get textGuidanceHint;

  /// Auxiliary images section title
  ///
  /// In en, this message translates to:
  /// **'Auxiliary Images'**
  String get auxiliaryImages;

  /// Delete image button
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImage;

  /// Delete image confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this image?'**
  String get deleteImageMessage;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter exercise name'**
  String get pleaseEnterName;

  /// Create success message
  ///
  /// In en, this message translates to:
  /// **'Exercise created successfully'**
  String get createSuccess;

  /// Update success message
  ///
  /// In en, this message translates to:
  /// **'Exercise updated successfully'**
  String get updateSuccess;

  /// Waiting for upload message
  ///
  /// In en, this message translates to:
  /// **'Waiting for upload to complete...'**
  String get waitingForUpload;

  /// Optional field indicator
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// End of list message
  ///
  /// In en, this message translates to:
  /// **'No more exercises'**
  String get noMoreData;

  /// Loading more indicator
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get loadingMore;

  /// Error message when keyframe extraction fails
  ///
  /// In en, this message translates to:
  /// **'Extraction failed'**
  String get extractionFailed;

  /// Button text to retry keyframe extraction
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryExtraction;

  /// Placeholder text when no keyframes available
  ///
  /// In en, this message translates to:
  /// **'No keyframes yet'**
  String get noKeyframesYet;

  /// Button text to extract current video frame manually
  ///
  /// In en, this message translates to:
  /// **'Extract Frame'**
  String get extractCurrentFrame;

  /// Loading text while extracting frame
  ///
  /// In en, this message translates to:
  /// **'Extracting...'**
  String get extractingFrame;

  /// Success message after frame extraction
  ///
  /// In en, this message translates to:
  /// **'Frame extracted successfully'**
  String get frameExtracted;

  /// Student detail page title
  ///
  /// In en, this message translates to:
  /// **'Student Details'**
  String get studentDetailTitle;

  /// Training records button text
  ///
  /// In en, this message translates to:
  /// **'Training Records'**
  String get trainingRecords;

  /// Message button text
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// Training sessions stat label
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// Adherence stat label
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get adherence;

  /// Training volume stat label
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// AI progress summary dialog title
  ///
  /// In en, this message translates to:
  /// **'AI Progress Summary'**
  String get aiProgressSummary;

  /// Training volume highlight label
  ///
  /// In en, this message translates to:
  /// **'Training Volume'**
  String get trainingVolume;

  /// Weight change highlight label
  ///
  /// In en, this message translates to:
  /// **'Weight Change'**
  String get weightLoss;

  /// Average strength highlight label
  ///
  /// In en, this message translates to:
  /// **'Avg Strength'**
  String get avgStrength;

  /// Starting weight stat
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get starting;

  /// Current weight stat
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// Weight change stat
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Target weight stat
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// Training history section title
  ///
  /// In en, this message translates to:
  /// **'Training History'**
  String get trainingHistory;

  /// Pending review status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Reviewed status
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewed;

  /// Videos count label
  ///
  /// In en, this message translates to:
  /// **'videos'**
  String get videos;

  /// Years age label
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// Feedback input placeholder
  ///
  /// In en, this message translates to:
  /// **'Add feedback...'**
  String get feedbackInputPlaceholder;

  /// Voice record button hint
  ///
  /// In en, this message translates to:
  /// **'Hold to Record'**
  String get holdToRecord;

  /// Release to send voice message
  ///
  /// In en, this message translates to:
  /// **'Release to Send'**
  String get releaseToSend;

  /// Slide up to cancel voice recording
  ///
  /// In en, this message translates to:
  /// **'Slide up to cancel'**
  String get slideUpToCancel;

  /// Recording voice indicator
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recordingVoice;

  /// Voice recording too short error
  ///
  /// In en, this message translates to:
  /// **'Recording too short'**
  String get voiceTooShort;

  /// Send image button
  ///
  /// In en, this message translates to:
  /// **'Send Image'**
  String get sendImage;

  /// Feedback history section title
  ///
  /// In en, this message translates to:
  /// **'Feedback History'**
  String get feedbackHistory;

  /// Empty state text for no feedback
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get noFeedbackYet;

  /// Text feedback type
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textFeedback;

  /// Voice feedback type
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceFeedback;

  /// Image feedback type
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageFeedback;

  /// Permission denied error
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// Microphone permission required message
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get microphonePermission;

  /// Failed to start recording error
  ///
  /// In en, this message translates to:
  /// **'Failed to start recording'**
  String get failedToStartRecording;

  /// Failed to stop recording error
  ///
  /// In en, this message translates to:
  /// **'Failed to stop recording'**
  String get failedToStopRecording;

  /// Failed to send feedback error
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback'**
  String get failedToSendFeedback;

  /// Failed to send voice error
  ///
  /// In en, this message translates to:
  /// **'Failed to send voice'**
  String get failedToSendVoice;

  /// Failed to pick image error
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// Time format: just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Edit image button
  ///
  /// In en, this message translates to:
  /// **'Edit Image'**
  String get editImage;

  /// Save edited image button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveEditedImage;

  /// Cancel editing button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelEdit;

  /// Image editing page title
  ///
  /// In en, this message translates to:
  /// **'Image Editing'**
  String get imageEditing;

  /// Uploading edited image message
  ///
  /// In en, this message translates to:
  /// **'Uploading edited image...'**
  String get uploadingEditedImage;

  /// Failed to edit image error
  ///
  /// In en, this message translates to:
  /// **'Failed to edit image'**
  String get editImageFailed;

  /// Current exercise plan label
  ///
  /// In en, this message translates to:
  /// **'Current Exercise Plan'**
  String get currentExercisePlan;

  /// Current diet plan label
  ///
  /// In en, this message translates to:
  /// **'Current Diet Plan'**
  String get currentDietPlan;

  /// Current supplement plan label
  ///
  /// In en, this message translates to:
  /// **'Current Supplement Plan'**
  String get currentSupplementPlan;

  /// No plan assigned label
  ///
  /// In en, this message translates to:
  /// **'No Plan'**
  String get noPlan;

  /// Loading message on splash screen
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splashLoading;

  /// Error message when loading user data fails on splash screen
  ///
  /// In en, this message translates to:
  /// **'Failed to load user data'**
  String get splashLoadError;

  /// Upcoming schedule section title on coach home page
  ///
  /// In en, this message translates to:
  /// **'Upcoming Schedule'**
  String get upcomingScheduleTitle;

  /// Pending reviews section title on coach home page
  ///
  /// In en, this message translates to:
  /// **'Pending Reviews'**
  String get pendingReviewsTitle;

  /// View more button text
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// Record training text for summary stats
  ///
  /// In en, this message translates to:
  /// **'record training'**
  String get recordTraining;

  /// Records to review label for summary stats
  ///
  /// In en, this message translates to:
  /// **'Records to Review'**
  String get recordsToReview;

  /// Unread messages label for summary stats
  ///
  /// In en, this message translates to:
  /// **'Unread Messages'**
  String get unreadMessagesLabel;

  /// No pending reviews message
  ///
  /// In en, this message translates to:
  /// **'No pending reviews'**
  String get noPendingReviews;

  /// No pending reviews description
  ///
  /// In en, this message translates to:
  /// **'All training records have been reviewed'**
  String get noPendingReviewsDesc;

  /// Generate AI summary button text
  ///
  /// In en, this message translates to:
  /// **'Generate AI Summary'**
  String get generateAISummary;

  /// Generating AI summary loading text
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generatingAISummary;

  /// AI summary generation failed title
  ///
  /// In en, this message translates to:
  /// **'Failed to Generate'**
  String get aiSummaryFailed;

  /// AI summary generation failed message
  ///
  /// In en, this message translates to:
  /// **'Unable to generate AI summary. Please try again later.'**
  String get aiSummaryFailedMessage;

  /// Provide feedback button text
  ///
  /// In en, this message translates to:
  /// **'Provide Feedback'**
  String get provideFeedback;

  /// Hide input bar button text
  ///
  /// In en, this message translates to:
  /// **'Hide Input'**
  String get hideInput;

  /// Exercise feedback history section title
  ///
  /// In en, this message translates to:
  /// **'{exerciseName} - Feedback History'**
  String exerciseFeedbackHistory(String exerciseName);

  /// Load more button text
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// Image preview page title
  ///
  /// In en, this message translates to:
  /// **'Preview Photo'**
  String get previewPhoto;

  /// AI analysis button text
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// Manual record button text
  ///
  /// In en, this message translates to:
  /// **'Manual Record'**
  String get manualRecord;

  /// Uploading state text
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// Image uploading progress text
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// Add feedback button text in read-only section
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get addFeedbackButton;

  /// Recent feedbacks section title
  ///
  /// In en, this message translates to:
  /// **'Recent Feedbacks'**
  String get recentFeedbacks;

  /// Carbohydrates nutrition label
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get carbohydrates;

  /// Saving image progress text
  ///
  /// In en, this message translates to:
  /// **'Saving image...'**
  String get savingImage;

  /// Deleting old image progress text
  ///
  /// In en, this message translates to:
  /// **'Cleaning up old image...'**
  String get deletingOldImage;

  /// Keyframe update success message
  ///
  /// In en, this message translates to:
  /// **'Keyframe updated successfully'**
  String get keyframeUpdated;

  /// Switch between front and back camera
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// Note about keyframe edits being visible to students
  ///
  /// In en, this message translates to:
  /// **'Students can see all edits to keyframes'**
  String get keyframeEditNote;

  /// Title for keyframe edit note dialog
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get keyframeEditNoteTitle;

  /// Title for meal details bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Meal Details'**
  String get mealDetails;

  /// Button text to save changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Button text to add food item
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get addFood;

  /// Button text to edit food item
  ///
  /// In en, this message translates to:
  /// **'Edit Food'**
  String get editFood;

  /// Button text to delete food item
  ///
  /// In en, this message translates to:
  /// **'Delete Food'**
  String get deleteFood;

  /// Label for food name input
  ///
  /// In en, this message translates to:
  /// **'Food Name'**
  String get foodName;

  /// Label for amount input
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Label for yesterday
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// Label for days ago
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// Food list section title
  ///
  /// In en, this message translates to:
  /// **'Food List'**
  String get foodList;

  /// Empty state for photos
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get noPhotos;

  /// Empty state for food list
  ///
  /// In en, this message translates to:
  /// **'No food items'**
  String get noFood;

  /// Nutrition summary label for custom food item
  ///
  /// In en, this message translates to:
  /// **'Nutrition Summary'**
  String get nutritionSummary;

  /// Placeholder for note input field
  ///
  /// In en, this message translates to:
  /// **'Add note...'**
  String get addNotePlaceholder;

  /// Error dialog title when trying to delete a template in use
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete Template'**
  String get cannotDeleteTemplate;

  /// Error message when trying to delete a template in use
  ///
  /// In en, this message translates to:
  /// **'This template is being used by {count} training plan(s). Please remove it from those plans first.'**
  String templateInUse(int count);

  /// Title for exercise guidance sheet
  ///
  /// In en, this message translates to:
  /// **'Exercise Guidance'**
  String get exerciseGuidance;

  /// Button text to view exercise guidance
  ///
  /// In en, this message translates to:
  /// **'View Guidance'**
  String get viewGuidance;

  /// Message when no guidance content is available
  ///
  /// In en, this message translates to:
  /// **'No guidance available for this exercise'**
  String get noGuidanceAvailable;

  /// Label for reference images section
  ///
  /// In en, this message translates to:
  /// **'Reference Images'**
  String get referenceImages;

  /// Placeholder for exercise name input
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseNamePlaceholder;

  /// Button text to extract keyframe from video
  ///
  /// In en, this message translates to:
  /// **'Extract\nKeyframe'**
  String get extractKeyframe;

  /// Empty state title when there are no training records
  ///
  /// In en, this message translates to:
  /// **'No Training Records'**
  String get noTrainingRecords;

  /// Training information section title
  ///
  /// In en, this message translates to:
  /// **'Training Info'**
  String get trainingInfo;

  /// Training date label
  ///
  /// In en, this message translates to:
  /// **'Training Date'**
  String get trainingDate;

  /// Total exercises count label
  ///
  /// In en, this message translates to:
  /// **'Total Exercises'**
  String get totalExercises;

  /// Exercise details section title
  ///
  /// In en, this message translates to:
  /// **'Exercise Details'**
  String get exerciseDetails;

  /// Video number label
  ///
  /// In en, this message translates to:
  /// **'Video {number}'**
  String videoNumber(int number);

  /// Video duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get videoDuration;

  /// Review status label
  ///
  /// In en, this message translates to:
  /// **'Review Status'**
  String get reviewStatus;

  /// Not reviewed status label
  ///
  /// In en, this message translates to:
  /// **'Not Reviewed'**
  String get notReviewed;

  /// Completed sets label
  ///
  /// In en, this message translates to:
  /// **'Completed Sets'**
  String get completedSets;

  /// Average weight label
  ///
  /// In en, this message translates to:
  /// **'Average Weight'**
  String get averageWeight;

  /// Total reps label
  ///
  /// In en, this message translates to:
  /// **'Total Reps'**
  String get totalReps;

  /// Set details label
  ///
  /// In en, this message translates to:
  /// **'Set Details'**
  String get setDetails;

  /// Daily training feedback section title
  ///
  /// In en, this message translates to:
  /// **'Daily Training Feedback'**
  String get dailyTrainingFeedback;

  /// Empty state message for daily training feedback
  ///
  /// In en, this message translates to:
  /// **'No feedback for this training yet'**
  String get noDailyTrainingFeedbackYet;

  /// Title for exercise list section
  ///
  /// In en, this message translates to:
  /// **'Exercise List'**
  String get exerciseList;

  /// Button text to add an exercise
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addExercise;

  /// Option to create a new exercise template
  ///
  /// In en, this message translates to:
  /// **'Create new \"{name}\"'**
  String createNewExercise(String name);

  /// Button to add guidance to exercise
  ///
  /// In en, this message translates to:
  /// **'Add Guidance'**
  String get addGuidance;

  /// Training sets section title
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get trainingSets;

  /// Button to add a training set
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSet;

  /// Message when exercise has no template
  ///
  /// In en, this message translates to:
  /// **'No Template Linked'**
  String get noTemplateLinked;

  /// Fallback exercise name when template not found
  ///
  /// In en, this message translates to:
  /// **'Unknown Exercise'**
  String get unknownExercise;

  /// Title for create plan page
  ///
  /// In en, this message translates to:
  /// **'Create Training Plan'**
  String get createPlanTitle;

  /// Subtitle for creation method selection
  ///
  /// In en, this message translates to:
  /// **'Choose how to start:'**
  String get chooseCreationMethod;

  /// AI guided creation button title
  ///
  /// In en, this message translates to:
  /// **'AI Guided Creation'**
  String get aiGuidedCreate;

  /// AI guided creation button description
  ///
  /// In en, this message translates to:
  /// **'Let AI help you quickly generate a plan'**
  String get aiGuidedDesc;

  /// Text import button title
  ///
  /// In en, this message translates to:
  /// **'Scan or Paste Text'**
  String get scanOrPasteText;

  /// Text import button description
  ///
  /// In en, this message translates to:
  /// **'Import from existing plan'**
  String get scanOrPasteDesc;

  /// Manual create link text
  ///
  /// In en, this message translates to:
  /// **'or... Manual Create'**
  String get orManualCreate;

  /// Text import view title
  ///
  /// In en, this message translates to:
  /// **'Import from Text'**
  String get textImportTitle;

  /// Text import view subtitle
  ///
  /// In en, this message translates to:
  /// **'Scan an image or paste text to import a training plan'**
  String get textImportSubtitle;

  /// Scan image tab label
  ///
  /// In en, this message translates to:
  /// **'Scan Image'**
  String get scanImage;

  /// Paste text tab label
  ///
  /// In en, this message translates to:
  /// **'Paste Text'**
  String get pasteText;

  /// Button to select image for OCR
  ///
  /// In en, this message translates to:
  /// **'Select Image to Scan'**
  String get selectImageToScan;

  /// Button to select another image
  ///
  /// In en, this message translates to:
  /// **'Select Another Image'**
  String get selectAnotherImage;

  /// Label for text input area
  ///
  /// In en, this message translates to:
  /// **'Extracted or Pasted Text'**
  String get extractedOrPastedText;

  /// Placeholder for text input
  ///
  /// In en, this message translates to:
  /// **'Paste or type training plan text here...'**
  String get pasteOrTypeHere;

  /// Example format section title
  ///
  /// In en, this message translates to:
  /// **'Example Format'**
  String get exampleFormat;

  /// Example format content
  ///
  /// In en, this message translates to:
  /// **'Day 1: Chest\nBench Press 3x10\nIncline Press 3x12\n\nDay 2: Back\nPull-ups 4x8\nRows 3x10'**
  String get exampleFormatContent;

  /// OCR extraction loading message
  ///
  /// In en, this message translates to:
  /// **'Extracting text...'**
  String get extractingText;

  /// AI parsing loading message
  ///
  /// In en, this message translates to:
  /// **'Parsing plan...'**
  String get parsingPlan;

  /// Button to start parsing text
  ///
  /// In en, this message translates to:
  /// **'Start Parsing'**
  String get startParsing;

  /// OCR extraction success message
  ///
  /// In en, this message translates to:
  /// **'Text extracted successfully! Please review and edit if needed.'**
  String get extractionSuccess;

  /// Add day button label
  ///
  /// In en, this message translates to:
  /// **'Add Day'**
  String get addDay;

  /// Empty state message when no day selected
  ///
  /// In en, this message translates to:
  /// **'Select a day or add a new one'**
  String get selectDayOrAddNew;

  /// Save plan button label
  ///
  /// In en, this message translates to:
  /// **'Save Plan'**
  String get savePlan;

  /// AI generation loading message
  ///
  /// In en, this message translates to:
  /// **'AI is generating training plan...'**
  String get aiGeneratingPlan;

  /// Current day being generated
  ///
  /// In en, this message translates to:
  /// **'Generating Day {day}'**
  String generatingDay(int day);

  /// Number of exercises added
  ///
  /// In en, this message translates to:
  /// **'{count} exercises added'**
  String addedExercises(int count);

  /// Number of days completed
  ///
  /// In en, this message translates to:
  /// **'{count} days completed'**
  String completedDays(int count);

  /// Empty state message for sets
  ///
  /// In en, this message translates to:
  /// **'No sets yet. Click \"Add Set\" button.'**
  String get noSetsYet;

  /// Edit plan page title
  ///
  /// In en, this message translates to:
  /// **'Edit Plan'**
  String get editPlan;

  /// Import success dialog title
  ///
  /// In en, this message translates to:
  /// **'Import Successful'**
  String get importSuccess;

  /// Number of import warnings
  ///
  /// In en, this message translates to:
  /// **'{count} warnings found'**
  String importWarnings(int count);

  /// Import success message
  ///
  /// In en, this message translates to:
  /// **'Please review and adjust the plan as needed.'**
  String get pleaseReview;
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
