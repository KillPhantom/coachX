// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get unitPreference => 'Unit Preference';

  @override
  String get metric => 'Metric';

  @override
  String get imperial => 'Imperial';

  @override
  String get language => 'Language';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get logOut => 'Log Out';

  @override
  String get subscription => 'Subscription';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get age => 'Age';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get coachInfo => 'Coach Info';

  @override
  String get student => 'Student';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get alert => 'Alert';

  @override
  String get featureInDevelopment => 'This feature is under development';

  @override
  String get avatarEditInDevelopment => 'Avatar editing is under development';

  @override
  String get accountSettingsInDevelopment =>
      'Account Settings is under development';

  @override
  String get helpCenterInDevelopment => 'Help Center is under development';

  @override
  String get selectUnitPreference => 'Select Unit Preference';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get close => 'Close';

  @override
  String get all => 'All';

  @override
  String get search => 'Search';

  @override
  String get know => 'Got it';

  @override
  String get tabHome => 'Home';

  @override
  String get tabStudents => 'Students';

  @override
  String get tabPlans => 'Plans';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabPlan => 'Plan';

  @override
  String get appName => 'CoachX';

  @override
  String get appTagline => 'AI Coaching Platform';

  @override
  String get emailPlaceholder => 'Email address';

  @override
  String get passwordPlaceholder => 'Password';

  @override
  String get passwordRequired => 'Please enter password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpNow => 'Sign up';

  @override
  String get getUserInfoFailed => 'Failed to get user info';

  @override
  String get getUserInfoTimeout => 'Get user info timeout, please try again';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get createAccount => 'Create your account';

  @override
  String get startYourJourney => 'Start your fitness journey';

  @override
  String get namePlaceholder => 'Name';

  @override
  String get nameRequired => 'Please enter your name';

  @override
  String get passwordMinLength => 'Password (at least 6 characters)';

  @override
  String get confirmPasswordPlaceholder => 'Confirm password';

  @override
  String get confirmPasswordRequired => 'Please confirm password';

  @override
  String get passwordMismatch => 'Passwords don\'t match';

  @override
  String get termsAgreement =>
      'By signing up, you agree to our Terms of Service and Privacy Policy';

  @override
  String get register => 'Register';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get loginNow => 'Login now';

  @override
  String get forgotPasswordInDevelopment =>
      'Forgot password feature is under development';

  @override
  String get registerFailed => 'Registration failed';

  @override
  String get coachHomeSummaryTitle => 'Summary';

  @override
  String studentsCompletedTrainingToday(int count) {
    return '$count students completed training today';
  }

  @override
  String unreadMessagesCount(int count) {
    return '$count unread messages';
  }

  @override
  String unreviewedTrainingsCount(int count) {
    return '$count training records need to be reviewed';
  }

  @override
  String get eventReminderTitle => 'Event Reminder';

  @override
  String get noUpcomingEvents => 'No upcoming events';

  @override
  String get recentActivityTitle => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get searchStudentPlaceholder => 'Search by student name';

  @override
  String studentCount(int count) {
    return '$count students';
  }

  @override
  String get noStudentsFound => 'No students found';

  @override
  String get noStudents => 'No students';

  @override
  String get tryAdjustFilters => 'Try adjusting filters';

  @override
  String get inviteStudentsTip => 'Tap the add button to invite students';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get inviteStudents => 'Invite students';

  @override
  String get studentDetails => 'Student Details';

  @override
  String get studentDeleted => 'Student deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String confirmDeleteStudent(String name) {
    return 'Are you sure to delete student \"$name\"? This action cannot be undone.';
  }

  @override
  String get filterOptions => 'Filter options';

  @override
  String get noTrainingPlans => 'No training plans';

  @override
  String get filterByTrainingPlan => 'Filter by training plan';

  @override
  String get invitationCodeManagement => 'Invitation Code Management';

  @override
  String get invitationCodeDescription =>
      'Generate invitation codes for student registration';

  @override
  String get contractDurationDays => 'Contract duration (days)';

  @override
  String get exampleDays => 'e.g., 180';

  @override
  String get remarkOptional => 'Remark (optional)';

  @override
  String get remarkExample => 'e.g., VIP exclusive';

  @override
  String get existingInvitationCodes => 'Existing invitation codes';

  @override
  String get noInvitationCodes => 'No invitation codes';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get generateInvitationCode => 'Generate invitation code';

  @override
  String get pleaseEnterContractDuration => 'Please enter contract duration';

  @override
  String get contractDurationRangeError =>
      'Contract duration must be between 1 and 365 days';

  @override
  String get generateFailed => 'Generate failed';

  @override
  String get invitationCodeGenerated =>
      'Invitation code generated successfully';

  @override
  String get invitationCodeCopied => 'Invitation code copied';

  @override
  String get selectAction => 'Select action';

  @override
  String get viewDetails => 'View details';

  @override
  String get assignPlan => 'Assign plan';

  @override
  String get deleteStudent => 'Delete student';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String get plansTitle => 'Plans';

  @override
  String get tabTraining => 'Training';

  @override
  String get tabDiet => 'Diet';

  @override
  String get tabSupplements => 'Supplements';

  @override
  String get copyPlan => 'Copy plan';

  @override
  String confirmCopyPlan(String planName) {
    return 'Are you sure to copy \"$planName\"?';
  }

  @override
  String get deletePlan => 'Delete plan';

  @override
  String confirmDeletePlan(String planName) {
    return 'Are you sure to delete \"$planName\"? This action cannot be undone.';
  }

  @override
  String get copySuccess => 'Copy successful';

  @override
  String get copyFailed => 'Copy failed';

  @override
  String get deleteSuccess => 'Delete successful';

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get noResults => 'No results';

  @override
  String noPlansFoundForQuery(String query) {
    return 'No plans found for \"$query\"';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noPlansYet => 'No plans yet';

  @override
  String createFirstPlan(String planType) {
    return 'Create your first $planType plan';
  }

  @override
  String get createPlan => 'Create plan';

  @override
  String get createNewPlanTitle => 'Create New Plan';

  @override
  String get createPlanSubtitle => 'What would you like to create today?';

  @override
  String get exercisePlanTitle => 'Exercise Plan';

  @override
  String get exercisePlanDesc =>
      'Create training schedules and workout routines';

  @override
  String get dietPlanTitle => 'Diet Plan';

  @override
  String get dietPlanDesc => 'Design meal plans and nutrition guidelines';

  @override
  String get supplementPlanTitle => 'Supplement Plan';

  @override
  String get supplementPlanDesc => 'Plan supplement schedules and dosages';

  @override
  String get assignToStudent => 'Assign to student';

  @override
  String get imperialUnit => 'Imperial (ft, lbs)';

  @override
  String get metricUnit => 'Metric (cm, kg)';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get confirmLogOut => 'Confirm log out';

  @override
  String get confirmLogOutMessage => 'Are you sure to log out?';

  @override
  String get addRecordTitle => 'Add Record';

  @override
  String get chooseRecordType => 'Choose a record type to add';

  @override
  String get trainingRecord => 'Training Record';

  @override
  String get dietRecord => 'Diet Record';

  @override
  String get supplementRecord => 'Supplement Record';

  @override
  String get bodyMeasurement => 'Body Measurement';

  @override
  String get studentHome => 'Student Home';

  @override
  String get toBeImplemented => 'To be implemented';

  @override
  String get trainingPageTitle => 'Training Page';

  @override
  String get noCoachInfo => 'No coach info';

  @override
  String get loadCoachInfoFailed => 'Failed to load coach info';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noStudentsMessage => 'No students yet, please add students first';

  @override
  String get noConversations => 'No conversations';

  @override
  String get noCoachOrConversations =>
      'You don\'t have a coach or conversations yet';

  @override
  String get conversationTitle => 'Conversation';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String get feedbackTabLabel => 'Feedback';

  @override
  String get messageInputPlaceholder => 'Type a message...';

  @override
  String get sendFailed => 'Send failed';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get supplementTimingNote => 'Note';

  @override
  String get supplementTimingNotePlaceholder => 'Add note...';

  @override
  String get weeklyStatus => 'Weekly Status';

  @override
  String daysRecorded(int count) {
    return '$count of 7 days recorded';
  }

  @override
  String get todayRecord => 'Today\'s Record';

  @override
  String get exerciseRecord => 'Exercise Record';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get calories => 'Calories';

  @override
  String mealsCount(int count) {
    return '$count meals';
  }

  @override
  String exercisesCount(int count) {
    return '$count exercises';
  }

  @override
  String supplementsCount(int count) {
    return '$count supplements';
  }

  @override
  String todayTraining(String name) {
    return 'Today: $name';
  }

  @override
  String get restDay => 'Rest Day';

  @override
  String get noPlanAssigned => 'No Plan Assigned';

  @override
  String get contactCoachForPlan => 'Contact your coach to get a training plan';

  @override
  String get viewAvailablePlans => 'View Available Plans';

  @override
  String get detail => 'Detail';

  @override
  String dayNumber(int day) {
    return 'Day $day';
  }

  @override
  String daysPerWeek(int days) {
    return '$days days/week';
  }

  @override
  String get noExercises => 'No exercises';

  @override
  String get assignPlansToStudent => 'Assign Plans to';

  @override
  String get exercisePlanSection => 'Training Plan';

  @override
  String get dietPlanSection => 'Diet Plan';

  @override
  String get supplementPlanSection => 'Supplement Plan';

  @override
  String get noPlanOption => 'No Plan (Remove Assignment)';

  @override
  String get currentPlan => 'Current';

  @override
  String get loadingPlans => 'Loading plans...';

  @override
  String get noPlansAvailable => 'No plans available';

  @override
  String get assignmentSaved => 'Plans assigned successfully';

  @override
  String get assignmentFailed => 'Assignment failed';

  @override
  String get notAssigned => 'Not Assigned';

  @override
  String get done => 'Done';
}
