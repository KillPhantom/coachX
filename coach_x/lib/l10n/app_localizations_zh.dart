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
  String get errorOccurred => '发生错误';

  @override
  String get retry => '重试';

  @override
  String get retryGeneration => '重新生成';

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
    return '$count 未读消息';
  }

  @override
  String unreviewedTrainingsCount(int count) {
    return '$count 记录待评价';
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
  String get generationFailed => '生成失败';

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
  String get confirmDelete => '确认删除';

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
  String get noResults => '没有找到结果';

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
  String get startRecording => '开始记录';

  @override
  String get viewRecords => '查看记录';

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
  String get weightChange => '体重';

  @override
  String get caloriesIntake => '卡路里';

  @override
  String get volumePR => '训练量';

  @override
  String get noDataStartRecording => '暂无数据，快开始记录';

  @override
  String get lastWeekData => '上周数据';

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
  String get serverError => '服务器错误，请重试';

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
  String videoWithNumber(int number) {
    return '视频 $number';
  }

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
  String get takePicture => '拍摄照片';

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
  String get cameraPermissionDenied => '相机权限被拒绝';

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
  String get usePhoto => '使用照片';

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
  String get recordExistsTitle => '记录已存在';

  @override
  String recordExistsMessage(String date) {
    return '您已有$date的记录，是否要替换？';
  }

  @override
  String get replace => '替换';

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
  String get videoDurationExceeded => '视频时长超过60秒';

  @override
  String get recordingVideo => '录制中...';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get videoTooLong => '视频时长超限';

  @override
  String get videoTooLongMessage => '请选择60秒以内的视频';

  @override
  String get videoProcessingFailed => '视频处理失败';

  @override
  String get videoCompressionFailed => '视频压缩失败，将上传原文件';

  @override
  String get photoLibraryPermissionDenied => '相册权限被拒绝';

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

  @override
  String get feedbackSearchPlaceholder => '搜索反馈...';

  @override
  String get feedbackStartDate => '开始日期';

  @override
  String get feedbackEndDate => '结束日期';

  @override
  String get feedbackToday => '今天';

  @override
  String get feedbackYesterday => '昨天';

  @override
  String get feedbackNoFeedback => '暂无反馈';

  @override
  String get feedbackNoFeedbackDesc => '训练反馈将显示在这里';

  @override
  String get feedbackLoadError => '加载反馈失败';

  @override
  String get feedbackRetry => '重试';

  @override
  String get trainingReviews => '训练记录';

  @override
  String get searchStudentName => '按学生姓名搜索';

  @override
  String get filterAll => '全部';

  @override
  String get filterPending => '待审核';

  @override
  String get filterReviewed => '已审核';

  @override
  String get statusPending => '待审核';

  @override
  String get statusReviewed => '已审核';

  @override
  String get noTrainingReviews => '暂无训练记录';

  @override
  String get noTrainingReviewsDesc => '训练记录将显示在这里';

  @override
  String get todaySummary => '今日总结';

  @override
  String get nutritionDetails => '营养详情';

  @override
  String get exerciseRecordVideo => '训练记录视频';

  @override
  String get keyframes => '关键帧';

  @override
  String get keyframesProcessing => '关键帧提取中...';

  @override
  String get noKeyframes => '暂无关键帧';

  @override
  String get viewKeyframe => '查看关键帧';

  @override
  String get fats => '脂肪';

  @override
  String get addFeedback => '为该组添加反馈...';

  @override
  String get complete => '完成';

  @override
  String get viewAll => '查看全部';

  @override
  String get noNutritionData => '暂无营养数据';

  @override
  String get noExerciseRecords => '暂无训练记录';

  @override
  String get savingFeedback => '正在保存反馈...';

  @override
  String get feedbackSaved => '反馈保存成功';

  @override
  String get failedToSave => '保存反馈失败';

  @override
  String get noDataFound => '未找到数据';

  @override
  String get details => '详情';

  @override
  String get trainingDetails => '训练详情';

  @override
  String get videoUploading => '上传中...';

  @override
  String get videoUploadFailed => '上传失败';

  @override
  String get retryUpload => '重试';

  @override
  String get processing => '处理中...';

  @override
  String get videoPlayer => '视频播放';

  @override
  String get videoLoadFailed => '视频加载失败';

  @override
  String get exerciseLibrary => '动作库';

  @override
  String get searchExercises => '搜索动作';

  @override
  String get exercises => '个动作';

  @override
  String get newExercise => '新建动作';

  @override
  String get noExercisesYet => '还没有动作';

  @override
  String get createFirstExercise => '创建你的第一个动作模板';

  @override
  String get tags => '标签';

  @override
  String get deleteExercise => '删除动作';

  @override
  String get confirmDeleteExercise => '确定要删除这个动作吗?';

  @override
  String get addTag => '新增标签';

  @override
  String get tagNameHint => '输入标签名称';

  @override
  String get tagAlreadyExists => '标签已存在';

  @override
  String get extractKeyframes => 'AI提取关键帧';

  @override
  String get extractingKeyframes => '提取中...';

  @override
  String get createExercise => '新建动作';

  @override
  String get editExercise => '编辑动作';

  @override
  String get exerciseName => '动作名称';

  @override
  String get exerciseNameHint => '输入动作名称';

  @override
  String get selectTags => '选择标签';

  @override
  String get atLeastOneTag => '请至少选择一个标签';

  @override
  String get guidanceVideo => '指导视频';

  @override
  String get deleteVideo => '删除视频';

  @override
  String get textGuidance => '文字说明';

  @override
  String get textGuidanceHint => '输入详细说明';

  @override
  String get auxiliaryImages => '辅助图片';

  @override
  String get deleteImage => '删除图片';

  @override
  String get deleteImageMessage => '确定删除这张图片吗？';

  @override
  String get pleaseEnterName => '请输入动作名称';

  @override
  String get createSuccess => '动作创建成功';

  @override
  String get updateSuccess => '动作更新成功';

  @override
  String get waitingForUpload => '等待上传完成...';

  @override
  String get optional => '可选';

  @override
  String get noMoreData => '没有更多动作了';

  @override
  String get loadingMore => '加载更多中...';

  @override
  String get extractionFailed => '提取失败';

  @override
  String get retryExtraction => '重试';

  @override
  String get noKeyframesYet => '暂无关键帧';

  @override
  String get extractCurrentFrame => '提取关键帧';

  @override
  String get extractingFrame => '提取中...';

  @override
  String get frameExtracted => '关键帧已提取';

  @override
  String get studentDetailTitle => '学生详情';

  @override
  String get trainingRecords => '训练记录';

  @override
  String get message => '发消息';

  @override
  String get sessions => '次训练';

  @override
  String get adherence => '完成率';

  @override
  String get volume => '容量';

  @override
  String get aiProgressSummary => 'AI 进度总结';

  @override
  String get trainingVolume => '训练容量';

  @override
  String get weightLoss => '体重变化';

  @override
  String get avgStrength => '平均力量';

  @override
  String get starting => '起始';

  @override
  String get current => '当前';

  @override
  String get change => '变化';

  @override
  String get target => '目标';

  @override
  String get trainingHistory => '训练历史';

  @override
  String get pending => '待审核';

  @override
  String get reviewed => '已审核';

  @override
  String get videos => '个视频';

  @override
  String get years => '岁';

  @override
  String get feedbackInputPlaceholder => '添加反馈...';

  @override
  String get holdToRecord => '长按录音';

  @override
  String get releaseToSend => '松手发送';

  @override
  String get slideUpToCancel => '上滑取消';

  @override
  String get recordingVoice => '录音中...';

  @override
  String get voiceTooShort => '录音时长过短';

  @override
  String get sendImage => '发送图片';

  @override
  String get feedbackHistory => '反馈历史';

  @override
  String get noFeedbackYet => '暂无反馈';

  @override
  String get textFeedback => '文字';

  @override
  String get voiceFeedback => '语音';

  @override
  String get imageFeedback => '图片';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get microphonePermission => '需要麦克风权限';

  @override
  String get failedToStartRecording => '开始录音失败';

  @override
  String get failedToStopRecording => '停止录音失败';

  @override
  String get failedToSendFeedback => '发送反馈失败';

  @override
  String get failedToSendVoice => '发送语音失败';

  @override
  String get failedToPickImage => '选择图片失败';

  @override
  String get justNow => '刚刚';

  @override
  String get editImage => '编辑图片';

  @override
  String get saveEditedImage => '保存';

  @override
  String get cancelEdit => '取消';

  @override
  String get imageEditing => '图片编辑';

  @override
  String get uploadingEditedImage => '正在上传编辑后的图片...';

  @override
  String get editImageFailed => '编辑图片失败';

  @override
  String get currentExercisePlan => '当前运动计划';

  @override
  String get currentDietPlan => '当前饮食计划';

  @override
  String get currentSupplementPlan => '当前补剂计划';

  @override
  String get noPlan => '无计划';

  @override
  String get splashLoading => '加载中...';

  @override
  String get splashLoadError => '加载用户数据失败';

  @override
  String get upcomingScheduleTitle => '即将到来的日程';

  @override
  String get pendingReviewsTitle => '待审核训练';

  @override
  String get viewMore => '查看更多';

  @override
  String get recordTraining => '学生打卡';

  @override
  String get recordsToReview => '待评价记录';

  @override
  String get unreadMessagesLabel => '未读消息';

  @override
  String get noPendingReviews => '暂无待审核记录';

  @override
  String get noPendingReviewsDesc => '所有训练记录已审核完毕';

  @override
  String get generateAISummary => '生成 AI 总结';

  @override
  String get generatingAISummary => '生成中...';

  @override
  String get aiSummaryFailed => '生成失败';

  @override
  String get aiSummaryFailedMessage => '无法生成 AI 总结，请稍后重试。';

  @override
  String get provideFeedback => '评价动作';

  @override
  String get hideInput => '收起输入';

  @override
  String exerciseFeedbackHistory(String exerciseName) {
    return '$exerciseName - 反馈历史';
  }

  @override
  String get loadMore => '加载更多';

  @override
  String get previewPhoto => '预览照片';

  @override
  String get aiAnalysis => 'AI 分析';

  @override
  String get manualRecord => '手动记录';

  @override
  String get uploading => '上传中...';

  @override
  String get uploadingImage => '正在上传图片...';

  @override
  String get addFeedbackButton => '添加反馈';

  @override
  String get recentFeedbacks => '最近反馈';

  @override
  String get carbohydrates => '碳水化合物';

  @override
  String get savingImage => '正在保存图片...';

  @override
  String get deletingOldImage => '正在清理旧图片...';

  @override
  String get keyframeUpdated => '关键帧已更新';

  @override
  String get switchCamera => '切换摄像头';

  @override
  String get keyframeEditNote => '所有对关键帧的编辑学生端都看得到';

  @override
  String get keyframeEditNoteTitle => '提示';

  @override
  String get mealDetails => '餐次详情';

  @override
  String get saveChanges => '保存修改';

  @override
  String get addFood => '添加食物';

  @override
  String get editFood => '编辑食物';

  @override
  String get deleteFood => '删除食物';

  @override
  String get foodName => '食物名称';

  @override
  String get amount => '数量';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get foodList => '食物列表';

  @override
  String get noPhotos => '暂无照片';

  @override
  String get noFood => '暂无食物';

  @override
  String get nutritionSummary => '总营养汇总';

  @override
  String get addNotePlaceholder => '添加备注...';

  @override
  String get cannotDeleteTemplate => '无法删除模板';

  @override
  String templateInUse(int count) {
    return '该模板正被 $count 个训练计划使用。请先从这些计划中移除。';
  }

  @override
  String get exerciseGuidance => '动作指导';

  @override
  String get viewGuidance => '查看指导';

  @override
  String get noGuidanceAvailable => '该动作暂无指导内容';

  @override
  String get referenceImages => '参考图片';

  @override
  String get exerciseNamePlaceholder => '动作名称';

  @override
  String get extractKeyframe => '截取\n关键帧';

  @override
  String get noTrainingRecords => '暂无训练记录';

  @override
  String get trainingInfo => '训练信息';

  @override
  String get trainingDate => '训练日期';

  @override
  String get totalExercises => '总动作数';

  @override
  String get exerciseDetails => '动作详情';

  @override
  String videoNumber(int number) {
    return '视频 $number';
  }

  @override
  String get videoDuration => '时长';

  @override
  String get reviewStatus => '批阅状态';

  @override
  String get notReviewed => '未批阅';

  @override
  String get completedSets => '完成组数';

  @override
  String get averageWeight => '平均重量';

  @override
  String get totalReps => '总次数';

  @override
  String get setDetails => '组次详情';

  @override
  String get dailyTrainingFeedback => '每日训练反馈';

  @override
  String get noDailyTrainingFeedbackYet => '本次训练暂无反馈';

  @override
  String get exerciseList => '动作列表';

  @override
  String get addExercise => '添加';

  @override
  String createNewExercise(String name) {
    return '创建新动作 \"$name\"';
  }

  @override
  String get addGuidance => '添加指导';

  @override
  String get trainingSets => '训练组';

  @override
  String get addSet => '添加组';

  @override
  String get noTemplateLinked => '未关联模板';

  @override
  String get unknownExercise => '未知动作';

  @override
  String get createPlanTitle => '创建训练计划';

  @override
  String get chooseCreationMethod => '选择创建方式：';

  @override
  String get aiGuidedCreate => 'AI 引导创建';

  @override
  String get aiGuidedDesc => '让 AI 帮你快速生成计划';

  @override
  String get scanOrPasteText => '扫描或粘贴文本';

  @override
  String get scanOrPasteDesc => '从现有计划导入';

  @override
  String get orManualCreate => '或者... 手动创建';

  @override
  String get textImportTitle => '从文本导入';

  @override
  String get textImportSubtitle => '扫描图片或粘贴文本导入训练计划';

  @override
  String get scanImage => '扫描图片';

  @override
  String get pasteText => '粘贴文本';

  @override
  String get selectImageToScan => '选择图片进行扫描';

  @override
  String get selectAnotherImage => '选择其他图片';

  @override
  String get extractedOrPastedText => '提取或粘贴的文本';

  @override
  String get pasteOrTypeHere => '粘贴或输入训练计划文本...';

  @override
  String get exampleFormat => '示例格式';

  @override
  String get exampleFormatContent =>
      '第 1 天：胸部\n卧推 3x10\n上斜卧推 3x12\n\n第 2 天：背部\n引体向上 4x8\n划船 3x10';

  @override
  String get extractingText => '正在提取文字...';

  @override
  String get parsingPlan => '正在解析计划...';

  @override
  String get startParsing => '开始解析';

  @override
  String get extractionSuccess => '文字提取成功！请检查并根据需要编辑。';

  @override
  String get addDay => '添加天';

  @override
  String get selectDayOrAddNew => '选择一天或添加新的训练日';

  @override
  String get savePlan => '保存计划';

  @override
  String get aiGeneratingPlan => 'AI 正在生成训练计划...';

  @override
  String generatingDay(int day) {
    return '正在生成第 $day 天';
  }

  @override
  String addedExercises(int count) {
    return '已添加 $count 个动作';
  }

  @override
  String completedDays(int count) {
    return '已完成 $count 天';
  }

  @override
  String get noSetsYet => '暂无组次。点击\"添加组\"按钮。';

  @override
  String get editPlan => '编辑计划';

  @override
  String get importSuccess => '导入成功';

  @override
  String importWarnings(int count) {
    return '发现 $count 个警告';
  }

  @override
  String get pleaseReview => '请检查并根据需要调整计划。';

  @override
  String get aiStreamingTitle => 'AI 训练计划生成器';

  @override
  String get aiStreamingSubtitle => '正在为您定制专属训练方案';

  @override
  String get step1Title => '分析训练要求';

  @override
  String get step1Description => '正在验证您的训练目标和参数...';

  @override
  String get step2Title => '生成训练计划';

  @override
  String get step2Description => 'AI 正在为您设计训练动作...';

  @override
  String get step3Title => '匹配动作库';

  @override
  String get step3Description => '正在检查可复用的动作...';

  @override
  String get step4Title => '完成生成';

  @override
  String get step4Description => '最后检查和验证...';

  @override
  String get summaryTitle => '生成完成！';

  @override
  String get statTotalDays => '训练天数';

  @override
  String get statTotalExercises => '训练动作';

  @override
  String get statReusedExercises => '复用';

  @override
  String get statNewExercises => '新建';

  @override
  String get viewFullPlan => '查看完整计划';

  @override
  String get confirmCreateTemplatesTitle => '创建动作模板';

  @override
  String confirmCreateTemplates(int count) {
    return '将创建 $count 个新动作模板到您的动作库';
  }

  @override
  String get confirmCreateButton => '确认创建';

  @override
  String get creatingTemplates => '正在创建模板...';

  @override
  String get mealRecordExists => '该餐次已有记录';

  @override
  String get confirmOverwriteMeal => '该餐次已有记录，继续保存将覆盖之前的记录，是否继续？';

  @override
  String get overwrite => '覆盖';

  @override
  String mealNumberFormat(int number) {
    return '第$number顿';
  }
}
