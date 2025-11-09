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
  String get loadFailed => 'Load Failed';

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
  String get confirmDelete => 'Are you sure you want to delete this record?';

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
  String get addRecordTitle => 'Record Your Activity';

  @override
  String get addRecordSubtitle => 'What would you like to add today?';

  @override
  String get chooseRecordType => 'Choose a record type to add';

  @override
  String get trainingRecord => 'Training Record';

  @override
  String get trainingRecordDesc => 'Log sets, reps, weight, and videos.';

  @override
  String get dietRecord => 'Record Meal';

  @override
  String get todayMealPlan => 'Today\'s Meal Plan';

  @override
  String get dietRecordDesc => 'Log food, quantity, and photos.';

  @override
  String get supplementRecord => 'Supplement Record';

  @override
  String get supplementPlan => 'Supplement Plan';

  @override
  String supplementsToTake(int count) {
    return '$count supplements to take';
  }

  @override
  String get bodyMeasurement => 'Record Body Stats';

  @override
  String get bodyMeasurementDesc => 'Log weight and upload body pictures.';

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
  String get todayRecord => 'Today\'s Meal Plan';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get totalNutrition => 'Total Nutrition';

  @override
  String get kcal => 'kcal';

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
  String get noExercises => 'No Exercises';

  @override
  String get sets => 'sets';

  @override
  String get reps => 'reps';

  @override
  String exerciseSetsWithWeight(int sets, String reps, String weight) {
    return '$sets sets x $reps reps @ $weight';
  }

  @override
  String exerciseSetsNoWeight(int sets, String reps) {
    return '$sets sets x $reps reps';
  }

  @override
  String exerciseSetsOnly(int sets) {
    return '$sets sets';
  }

  @override
  String get video => 'Video';

  @override
  String get coachNotes => 'Coach Notes:';

  @override
  String get aiGuidanceInDevelopment => 'AI Guidance Feature Coming Soon';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get ok => 'OK';

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

  @override
  String get save => 'Save';

  @override
  String get noCoachTitle => 'No Coach Assigned';

  @override
  String get noCoachMessage => 'Please contact support to get a coach assigned';

  @override
  String get planTabTraining => 'Training';

  @override
  String get planTabDiet => 'Diet';

  @override
  String get planTabSupplements => 'Supplements';

  @override
  String get coachsPlan => 'Coach\'s Plan';

  @override
  String get coachNote => 'Coach Note';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get noExercisesForBodyPart => 'No exercises for this body part';

  @override
  String get mealRecord => 'Meal Record';

  @override
  String get coachSuggestion => 'Coach Suggestion';

  @override
  String get totalMacros => 'Total Macros';

  @override
  String get addRecord => 'Add Record';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get takePicture => 'Take Picture';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get commentsOrQuestions => 'Comments or Questions';

  @override
  String get saveMealRecord => 'Save Meal Record';

  @override
  String get typeYourMessageHere => 'Type your message here...';

  @override
  String get mealCompleted => 'Completed';

  @override
  String get markAsComplete => 'Mark as Complete';

  @override
  String get editMeal => 'Edit';

  @override
  String get recordSaved => 'Record saved successfully';

  @override
  String get recordSaveFailed => 'Failed to save record';

  @override
  String get noMealsToday => 'No meals planned for today';

  @override
  String macrosFormat(int protein, int carbs, int fat) {
    return '${protein}P/${carbs}C/${fat}F';
  }

  @override
  String get aiFoodScanner => 'AI Food Scanner';

  @override
  String get scanFood => 'Scan Food';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get positionFoodInFrame => 'Position food within the frame';

  @override
  String get foodAnalysisResults => 'Analysis Results';

  @override
  String get estimatedWeight => 'Estimated Weight';

  @override
  String get adjustValues => 'Adjust values if needed';

  @override
  String get selectMeal => 'Select Meal';

  @override
  String get saveToMeal => 'Save to Meal';

  @override
  String recognizedFoods(int count) {
    return '$count foods recognized';
  }

  @override
  String get cameraPermissionDenied =>
      'Camera permission denied. Please enable camera access in Settings.';

  @override
  String get analysisFailed => 'Analysis Failed';

  @override
  String get plannedNutrition => 'Planned';

  @override
  String get mealProgress => 'Progress';

  @override
  String get aiDetectedFoods => 'Detected Foods';

  @override
  String get caloriesInput => 'Calories';

  @override
  String get proteinInput => 'Protein (g)';

  @override
  String get carbsInput => 'Carbs (g)';

  @override
  String get fatInput => 'Fat (g)';

  @override
  String get aiDetectButton => 'AI Smart Detection';

  @override
  String get addFoodRecord => 'Add Food Record';

  @override
  String get selectMealToAnalyze => 'Select meal to analyze';

  @override
  String get recordSavedSuccess => 'Food record saved successfully';

  @override
  String get aiScannerMode => 'AI Scanner';

  @override
  String get simpleRecordMode => 'Simple Record';

  @override
  String get aiAnalyzing => 'AI analyzing your food...';

  @override
  String get aiAnalysisProgress => 'Analysis Progress';

  @override
  String get selectMealToSave => 'Select meal to save';

  @override
  String get bodyStatsHistory => 'Body Stats History';

  @override
  String get recordBodyStats => 'Record Body Stats';

  @override
  String get bodyFat => 'Body Fat %';

  @override
  String get bodyFatOptional => 'Body Fat % (Optional)';

  @override
  String get skipPhoto => 'Skip Photo';

  @override
  String get enterWeight => 'Enter Weight';

  @override
  String get enterBodyFat => 'Enter Body Fat %';

  @override
  String get last14Days => 'Last 14 Days';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get last90Days => 'Last 90 Days';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get noBodyStatsData => 'No body stats data yet';

  @override
  String get weightTrend => 'Weight Trend';

  @override
  String get recordDeleted => 'Record deleted successfully';

  @override
  String get recordUpdated => 'Record updated successfully';

  @override
  String get maxPhotosReached => 'Maximum 3 photos allowed';

  @override
  String get history => 'History';

  @override
  String get photos => 'Photos';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get myRecordings => 'My Recordings';

  @override
  String get recordVideo => 'Record Video';

  @override
  String get set => 'Set';

  @override
  String get quickComplete => 'Quick Complete';

  @override
  String get completed => 'Completed';

  @override
  String get videoDurationExceeded => 'Video must be ≤ 1 minute';

  @override
  String get recordingVideo => 'Recording...';

  @override
  String get selectFromGallery => 'Select from gallery';

  @override
  String get startTimerConfirmTitle => 'Start Timer';

  @override
  String get startTimerConfirmMessage => 'Start training timer?';

  @override
  String get startTimerButton => 'Start';

  @override
  String get weightPlaceholder => 'Bodyweight/60kg';

  @override
  String get timeSpentLabel => 'Time Spent';

  @override
  String get addCustomExerciseHint => 'Tap \'+\' to add custom exercise';

  @override
  String completedCount(int count) {
    return '$count completed';
  }

  @override
  String get currentExercise => 'Current Exercise';

  @override
  String get totalDuration => 'Total Duration';

  @override
  String get congratsTitle => 'Congrats!';

  @override
  String get congratsMessage => 'You have finished all the exercises today!';

  @override
  String get congratsMessageCompact => 'Congrats! All exercises done!';

  @override
  String get createNewPlan => 'Create New Plan';

  @override
  String get selectPlan => 'Select Plan';

  @override
  String get myPlans => 'My Plans';

  @override
  String get coachPlan => 'Coach\'s Plan';
}
