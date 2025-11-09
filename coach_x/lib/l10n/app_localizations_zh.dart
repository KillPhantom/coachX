// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get profile => '个人资料';

  @override
  String get settings => '设置';

  @override
  String get notifications => '通知';

  @override
  String get unitPreference => '单位偏好';

  @override
  String get metric => '公制';

  @override
  String get imperial => '英制';

  @override
  String get language => '语言';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get accountSettings => '账户设置';

  @override
  String get helpCenter => '帮助中心';

  @override
  String get logOut => '退出登录';

  @override
  String get subscription => '订阅';

  @override
  String get personalInformation => '个人信息';

  @override
  String get age => '年龄';

  @override
  String get height => '身高';

  @override
  String get weight => '体重';

  @override
  String get coachInfo => '教练信息';

  @override
  String get student => '学生';

  @override
  String get errorOccurred => '出错了';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get loading => '加载中...';

  @override
  String get alert => '提示';

  @override
  String get featureInDevelopment => '功能开发中';

  @override
  String get avatarEditInDevelopment => '头像编辑功能开发中';

  @override
  String get accountSettingsInDevelopment => '账户设置功能开发中';

  @override
  String get helpCenterInDevelopment => '帮助中心功能开发中';

  @override
  String get selectUnitPreference => '选择单位偏好';

  @override
  String get success => '成功';

  @override
  String get error => '错误';

  @override
  String get delete => '删除';

  @override
  String get copy => '复制';

  @override
  String get close => '关闭';

  @override
  String get all => '全部';

  @override
  String get search => '搜索';

  @override
  String get know => '知道了';

  @override
  String get tabHome => '首页';

  @override
  String get tabStudents => '学生';

  @override
  String get tabPlans => '计划';

  @override
  String get tabChat => '聊天';

  @override
  String get tabProfile => '资料';

  @override
  String get tabPlan => '计划';

  @override
  String get appName => 'CoachX';

  @override
  String get appTagline => 'AI教练学生管理平台';

  @override
  String get emailPlaceholder => '邮箱地址';

  @override
  String get passwordPlaceholder => '密码';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get login => '登录';

  @override
  String get noAccount => '还没有账号？';

  @override
  String get signUpNow => '立即注册';

  @override
  String get getUserInfoFailed => '获取用户信息失败';

  @override
  String get getUserInfoTimeout => '获取用户信息超时，请重试';

  @override
  String get loginFailed => '登录失败';

  @override
  String get createAccount => '创建您的账号';

  @override
  String get startYourJourney => '开始您的健身之旅';

  @override
  String get namePlaceholder => '姓名';

  @override
  String get nameRequired => '请输入姓名';

  @override
  String get passwordMinLength => '密码（至少6位）';

  @override
  String get confirmPasswordPlaceholder => '确认密码';

  @override
  String get confirmPasswordRequired => '请确认密码';

  @override
  String get passwordMismatch => '两次输入的密码不一致';

  @override
  String get termsAgreement => '注册即表示您同意我们的服务条款和隐私政策';

  @override
  String get register => '注册';

  @override
  String get hasAccount => '已有账号？';

  @override
  String get loginNow => '立即登录';

  @override
  String get forgotPasswordInDevelopment => '忘记密码功能开发中';

  @override
  String get registerFailed => '注册失败';

  @override
  String get coachHomeSummaryTitle => '统计概览';

  @override
  String studentsCompletedTrainingToday(int count) {
    return '$count 位学生完成了今天的训练';
  }

  @override
  String unreadMessagesCount(int count) {
    return '$count 条未读消息';
  }

  @override
  String unreviewedTrainingsCount(int count) {
    return '$count 条训练记录待审核';
  }

  @override
  String get eventReminderTitle => '事件提醒';

  @override
  String get noUpcomingEvents => '暂无待办事项';

  @override
  String get recentActivityTitle => '最近活动';

  @override
  String get noRecentActivity => '暂无最近活动';

  @override
  String get searchStudentPlaceholder => '搜索学生姓名';

  @override
  String studentCount(int count) {
    return '$count 位学生';
  }

  @override
  String get noStudentsFound => '未找到学生';

  @override
  String get noStudents => '暂无学生';

  @override
  String get tryAdjustFilters => '试试调整筛选条件';

  @override
  String get inviteStudentsTip => '点击右上角添加按钮邀请学生';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get inviteStudents => '邀请学生';

  @override
  String get studentDetails => '学生详情';

  @override
  String get studentDeleted => '学生已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String confirmDeleteStudent(String name) {
    return '确定要删除学生 \"$name\" 吗？此操作不可恢复。';
  }

  @override
  String get filterOptions => '筛选条件';

  @override
  String get noTrainingPlans => '暂无训练计划';

  @override
  String get filterByTrainingPlan => '按训练计划筛选';

  @override
  String get invitationCodeManagement => '邀请码管理';

  @override
  String get invitationCodeDescription => '生成新的邀请码供学生注册使用';

  @override
  String get contractDurationDays => '签约时长（天）';

  @override
  String get exampleDays => '例如: 180';

  @override
  String get remarkOptional => '备注（可选）';

  @override
  String get remarkExample => '例如: VIP会员专属';

  @override
  String get existingInvitationCodes => '现有邀请码';

  @override
  String get noInvitationCodes => '暂无邀请码';

  @override
  String get loadFailed => '加载失败';

  @override
  String get generateInvitationCode => '生成邀请码';

  @override
  String get pleaseEnterContractDuration => '请输入签约时长';

  @override
  String get contractDurationRangeError => '签约时长必须在1-365天之间';

  @override
  String get generateFailed => '生成失败';

  @override
  String get invitationCodeGenerated => '邀请码生成成功';

  @override
  String get invitationCodeCopied => '邀请码已复制';

  @override
  String get selectAction => '选择操作';

  @override
  String get viewDetails => '查看详情';

  @override
  String get assignPlan => '分配计划';

  @override
  String get deleteStudent => '删除学生';

  @override
  String get confirmDelete => '确定要删除这条记录吗？';

  @override
  String get plansTitle => '计划';

  @override
  String get tabTraining => '训练计划';

  @override
  String get tabDiet => '饮食计划';

  @override
  String get tabSupplements => '补剂计划';

  @override
  String get copyPlan => '复制计划';

  @override
  String confirmCopyPlan(String planName) {
    return '确定要复制 \"$planName\" 吗？';
  }

  @override
  String get deletePlan => '删除计划';

  @override
  String confirmDeletePlan(String planName) {
    return '确定要删除 \"$planName\" 吗？此操作无法撤销。';
  }

  @override
  String get copySuccess => '复制成功';

  @override
  String get copyFailed => '复制失败';

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get refreshFailed => '刷新失败';

  @override
  String get noResults => '未找到结果';

  @override
  String noPlansFoundForQuery(String query) {
    return '未找到 \"$query\" 的计划';
  }

  @override
  String get clearSearch => '清除搜索';

  @override
  String get noPlansYet => '暂无计划';

  @override
  String createFirstPlan(String planType) {
    return '创建你的第一个$planType计划';
  }

  @override
  String get createPlan => '创建计划';

  @override
  String get createNewPlanTitle => '创建新计划';

  @override
  String get createPlanSubtitle => '你今天想创建什么？';

  @override
  String get exercisePlanTitle => '训练计划';

  @override
  String get exercisePlanDesc => '创建训练日程和运动计划';

  @override
  String get dietPlanTitle => '饮食计划';

  @override
  String get dietPlanDesc => '设计膳食计划和营养指南';

  @override
  String get supplementPlanTitle => '补剂计划';

  @override
  String get supplementPlanDesc => '规划补剂时间表和剂量';

  @override
  String get assignToStudent => '分配给学生';

  @override
  String get imperialUnit => '英制（英尺、磅）';

  @override
  String get metricUnit => '公制（厘米、公斤）';

  @override
  String get updateFailed => '更新失败';

  @override
  String get confirmLogOut => '确认登出';

  @override
  String get confirmLogOutMessage => '确定要登出吗？';

  @override
  String get addRecordTitle => '记录你的活动';

  @override
  String get addRecordSubtitle => '今天想添加什么记录？';

  @override
  String get chooseRecordType => '选择要添加的记录类型';

  @override
  String get trainingRecord => '训练记录';

  @override
  String get trainingRecordDesc => '记录组数、次数、重量和视频。';

  @override
  String get dietRecord => '记录饮食';

  @override
  String get todayMealPlan => '今日饮食计划';

  @override
  String get dietRecordDesc => '记录食物、份量和照片。';

  @override
  String get supplementRecord => '补剂记录';

  @override
  String get supplementPlan => '补剂计划';

  @override
  String supplementsToTake(int count) {
    return '$count 个补剂需服用';
  }

  @override
  String get bodyMeasurement => '记录身体数据';

  @override
  String get bodyMeasurementDesc => '记录体重并上传身体照片。';

  @override
  String get studentHome => '学生首页';

  @override
  String get toBeImplemented => '待实现';

  @override
  String get trainingPageTitle => '学生训练页面';

  @override
  String get noCoachInfo => '暂无教练信息';

  @override
  String get loadCoachInfoFailed => '加载教练信息失败';

  @override
  String get privacySettings => '隐私设置';

  @override
  String get messagesTitle => '消息';

  @override
  String get noStudentsMessage => '当前没有学生，请先添加学生';

  @override
  String get noConversations => '暂无对话';

  @override
  String get noCoachOrConversations => '您还没有教练或对话';

  @override
  String get conversationTitle => '对话';

  @override
  String get chatTabLabel => '聊天';

  @override
  String get feedbackTabLabel => '反馈';

  @override
  String get messageInputPlaceholder => '输入消息...';

  @override
  String get sendFailed => '发送失败';

  @override
  String get userNotLoggedIn => '用户未登录';

  @override
  String get errorTitle => '出错了';

  @override
  String get supplementTimingNote => '备注';

  @override
  String get supplementTimingNotePlaceholder => '添加备注...';

  @override
  String get weeklyStatus => '本周状态';

  @override
  String daysRecorded(int count) {
    return '已记录 $count 天';
  }

  @override
  String get todayRecord => '今日饮食计划';

  @override
  String get protein => '蛋白质';

  @override
  String get carbs => '碳水';

  @override
  String get fat => '脂肪';

  @override
  String get totalNutrition => '总营养值';

  @override
  String get kcal => '千卡';

  @override
  String get calories => '卡路里';

  @override
  String mealsCount(int count) {
    return '$count 餐';
  }

  @override
  String exercisesCount(int count) {
    return '$count 个动作';
  }

  @override
  String supplementsCount(int count) {
    return '$count 个补剂';
  }

  @override
  String todayTraining(String name) {
    return '今日: $name';
  }

  @override
  String get restDay => '休息日';

  @override
  String get noPlanAssigned => '暂无计划';

  @override
  String get contactCoachForPlan => '请联系教练分配训练计划';

  @override
  String get viewAvailablePlans => '查看可用计划';

  @override
  String get detail => '详情';

  @override
  String dayNumber(int day) {
    return '第 $day 天';
  }

  @override
  String daysPerWeek(int days) {
    return '$days 天/周';
  }

  @override
  String get noExercises => '暂无训练动作';

  @override
  String get sets => '组';

  @override
  String get reps => '次';

  @override
  String exerciseSetsWithWeight(int sets, String reps, String weight) {
    return '$sets组 x $reps次 @ $weight';
  }

  @override
  String exerciseSetsNoWeight(int sets, String reps) {
    return '$sets组 x $reps次';
  }

  @override
  String exerciseSetsOnly(int sets) {
    return '$sets组';
  }

  @override
  String get video => '视频';

  @override
  String get coachNotes => '教练备注：';

  @override
  String get aiGuidanceInDevelopment => 'AI指导功能开发中';

  @override
  String get comingSoon => '即将推出';

  @override
  String get ok => '确定';

  @override
  String get assignPlansToStudent => '分配计划给';

  @override
  String get exercisePlanSection => '训练计划';

  @override
  String get dietPlanSection => '饮食计划';

  @override
  String get supplementPlanSection => '补剂计划';

  @override
  String get noPlanOption => '无计划（移除分配）';

  @override
  String get currentPlan => '当前';

  @override
  String get loadingPlans => '加载计划中...';

  @override
  String get noPlansAvailable => '暂无可用计划';

  @override
  String get assignmentSaved => '计划分配成功';

  @override
  String get assignmentFailed => '分配失败';

  @override
  String get notAssigned => '未分配';

  @override
  String get done => '完成';

  @override
  String get save => '保存';

  @override
  String get noCoachTitle => '暂无教练';

  @override
  String get noCoachMessage => '请联系客服获取教练';

  @override
  String get planTabTraining => '训练';

  @override
  String get planTabDiet => '饮食';

  @override
  String get planTabSupplements => '补剂';

  @override
  String get coachsPlan => '教练计划';

  @override
  String get coachNote => '教练备注';

  @override
  String get kg => '公斤';

  @override
  String get lbs => '磅';

  @override
  String get noExercisesForBodyPart => '该部位暂无动作';

  @override
  String get mealRecord => '饮食记录';

  @override
  String get coachSuggestion => '教练建议';

  @override
  String get totalMacros => '总营养';

  @override
  String get addRecord => '添加记录';

  @override
  String get editRecord => '编辑记录';

  @override
  String get takePicture => '拍照';

  @override
  String get uploadImage => '上传图片';

  @override
  String get commentsOrQuestions => '评论或问题';

  @override
  String get saveMealRecord => '保存饮食记录';

  @override
  String get typeYourMessageHere => '在此输入您的消息...';

  @override
  String get mealCompleted => '已完成';

  @override
  String get markAsComplete => '标记为完成';

  @override
  String get editMeal => '编辑';

  @override
  String get recordSaved => '记录保存成功';

  @override
  String get recordSaveFailed => '保存记录失败';

  @override
  String get noMealsToday => '今天没有安排餐次';

  @override
  String macrosFormat(int protein, int carbs, int fat) {
    return '${protein}P/${carbs}C/${fat}F';
  }

  @override
  String get aiFoodScanner => 'AI食物扫描';

  @override
  String get scanFood => '扫描食物';

  @override
  String get uploadPhoto => '上传照片';

  @override
  String get analyzing => '分析中...';

  @override
  String get positionFoodInFrame => '将食物置于框内';

  @override
  String get foodAnalysisResults => '分析结果';

  @override
  String get estimatedWeight => '估算重量';

  @override
  String get adjustValues => '如需要可调整数值';

  @override
  String get selectMeal => '选择餐次';

  @override
  String get saveToMeal => '保存到餐次';

  @override
  String recognizedFoods(int count) {
    return '识别到 $count 种食物';
  }

  @override
  String get cameraPermissionDenied => '相机权限被拒绝，请在设置中启用相机访问权限。';

  @override
  String get analysisFailed => '分析失败';

  @override
  String get plannedNutrition => '计划营养';

  @override
  String get mealProgress => '本餐进度';

  @override
  String get aiDetectedFoods => '包含食物';

  @override
  String get caloriesInput => '热量';

  @override
  String get proteinInput => '蛋白质 (g)';

  @override
  String get carbsInput => '碳水 (g)';

  @override
  String get fatInput => '脂肪 (g)';

  @override
  String get aiDetectButton => 'AI 智能检测';

  @override
  String get addFoodRecord => '添加食物记录';

  @override
  String get selectMealToAnalyze => '选择餐次';

  @override
  String get recordSavedSuccess => '食物记录已成功保存';

  @override
  String get aiScannerMode => 'AI扫描';

  @override
  String get simpleRecordMode => '简单记录';

  @override
  String get aiAnalyzing => 'AI正在分析您的食物...';

  @override
  String get aiAnalysisProgress => '分析进度';

  @override
  String get selectMealToSave => '选择要保存的餐次';

  @override
  String get bodyStatsHistory => '身体数据历史';

  @override
  String get recordBodyStats => '记录身体数据';

  @override
  String get bodyFat => '体脂率 %';

  @override
  String get bodyFatOptional => '体脂率 %（可选）';

  @override
  String get skipPhoto => '跳过拍照';

  @override
  String get enterWeight => '输入体重';

  @override
  String get enterBodyFat => '输入体脂率 %';

  @override
  String get last14Days => '最近14天';

  @override
  String get last30Days => '最近30天';

  @override
  String get last90Days => '最近90天';

  @override
  String get deleteRecord => '删除记录';

  @override
  String get noBodyStatsData => '暂无身体数据';

  @override
  String get weightTrend => '体重趋势';

  @override
  String get recordDeleted => '记录已删除';

  @override
  String get recordUpdated => '记录已更新';

  @override
  String get maxPhotosReached => '最多上传3张照片';

  @override
  String get history => '历史记录';

  @override
  String get photos => '照片';

  @override
  String get takePhoto => '拍照';

  @override
  String get myRecordings => '我的录制';

  @override
  String get recordVideo => '录制视频';

  @override
  String get set => '组';

  @override
  String get quickComplete => '快捷完成';

  @override
  String get completed => '已完成';

  @override
  String get videoDurationExceeded => '视频时长不能超过1分钟';

  @override
  String get recordingVideo => '录制中...';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get startTimerConfirmTitle => '开始计时';

  @override
  String get startTimerConfirmMessage => '确认开始训练计时吗？';

  @override
  String get startTimerButton => '开始';

  @override
  String get weightPlaceholder => '自重/60kg';

  @override
  String get timeSpentLabel => '用时';

  @override
  String get addCustomExerciseHint => '点击右上角\"+\"添加自定义动作';

  @override
  String completedCount(int count) {
    return '$count 已完成';
  }

  @override
  String get currentExercise => '当前动作';

  @override
  String get totalDuration => '总时长';

  @override
  String get congratsTitle => '恭喜！';

  @override
  String get congratsMessage => '你已完成今天的所有训练动作！';

  @override
  String get congratsMessageCompact => '恭喜！所有训练已完成！';

  @override
  String get createNewPlan => '创建新计划';

  @override
  String get selectPlan => '选择计划';

  @override
  String get myPlans => '我的计划';

  @override
  String get coachPlan => '教练计划';
}
