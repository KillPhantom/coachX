## Backend APIs (Cloud Functions)

- 用户
  - fetchUserInfo(userId?)
  - login(userInfo)
  - updateUserInfo(display_name?, born_date?, height?, expire_at?, gender?, need_reply?, initial_weight?, avatar_url?, active_role?)

- 学员与统计
  - fetchStudents(pageSize?, pageNumber?, otherParams?)
  - fetchStudentsStats()

- 计划 CRUD 与分配
  - exercisePlan: action in [create | update | delete | get | list | copy]
  - dietPlan: action in [create | update | delete | get | list | copy]
  - supplementPlan: action in [create | update | delete | get | list | copy]
  - assignPlan: action in [assign | unassign] with { planType, planId, studentId }
  - getStudentPlans(planType?, studentId?)

- 学生训练
  - upsertTodayTraining(dailyTraining, studentID, date, overwrite?)
  - fetchTodayTraining(studentID, date)
  - fetchTrainingHistory(studentID, limit?, status?)
  - fetchLatestTraining(studentID)
  - fetchUnreviewedTrainings()

- 动作反馈
  - upsertExerciseFeedback(exercisePlanId, exerciseIndex, exerciseName, studentId, coachId, trainingDate, message)
  - getExerciseFeedback(exercisePlanId, exerciseIndex, trainingDate)
  - getExerciseHistoryFeedback(exercisePlanId, studentId, coachId, exerciseName, exerciseIndex, limit?)

- 身体测量
  - saveMeasurementSession(session)
  - deleteMeasurementSession(sessionId)
  - fetchMeasurementSessions(studentID, startDate?, endDate?)

- 课程排班与预约（单表设计）
  - createCoachAvailableSlots(coachId, timeSlots[], coachName, type, coachNote?)
  - fetchCoachAvailableSlots(coachId, startDate, endDate, type?, status?)
  - updateTimeSlot(slotId, coachNote?, studentId?, status?, startTime?, endTime?, studentNote?, coachId?)
  - deleteTimeSlot(slotId, coachId)
  - createCourseBooking(studentId, coachId, startTimestamp, endTimestamp, studentNote?, studentName?, duration?)
  - fetchCoachBookings(coachId, startDate, endDate)

- 食物库
  - foodLibrary: action in [create | update | delete | get | list | search]

- 邀请码
  - fetchInvitationCode()
  - verifyInvitationCode(code)
  - generateInvitationCodes(codeCount?, codeType?)
  - generateStudentInvitationCode(totalDays?)

- AI 生成
  - generateAITrainingPlan(prompt, dayIndex?, activeTab?)


## Database Schemas (Document Database)

### users
| columnName | data type |
| --- | --- |
| _id | string |
| open_id | string |
| role | string |
| active_role | string |
| name | string |
| display_name | string |
| avatar_url | string |
| gender | string |
| coach_id | string |
| is_admin | boolean |
| is_verified | boolean |
| need_reply | boolean |
| born_date | string |
| height | number |
| initial_weight | number |
| expire_at | number |
| last_active_time | number |

### exercise_plan
| columnName | data type |
| --- | --- |
| _id | string |
| name | string |
| description | string |
| cyclePattern | string |
| days | ExerciseTrainingDay[] |
| ownerId | string |
| studentIds | string[] |
| isTemplate | boolean |
| createdAt | number |
| updatedAt | number |

ExerciseTrainingDay
| columnName | data type |
| --- | --- |
| day | number |
| type | string |
| name | string |
| exercises | Exercise[] |
| completed | boolean |

Exercise
| columnName | data type |
| --- | --- |
| name | string |
| note | string |
| type | "strength" | "cardio" |
| sets | TrainingSet[] |
| completed | boolean |
| detailGuide | string |
| demoVideos | string[] |

TrainingSet
| columnName | data type |
| --- | --- |
| reps | string |
| weight | string |
| completed | boolean |

### diet_plan
| columnName | data type |
| --- | --- |
| _id | string |
| name | string |
| description | string |
| cyclePattern | string |
| days | DietDay[] |
| ownerId | string |
| studentIds | string[] |
| isTemplate | boolean |
| createdAt | number |
| updatedAt | number |

DietDay
| columnName | data type |
| --- | --- |
| day | number |
| type | string |
| name | string |
| diet | Diet |
| completed | boolean |

Diet
| columnName | data type |
| --- | --- |
| macros | Macros | null |
| meals | Meal[] |

Meal
| columnName | data type |
| --- | --- |
| name | string |
| note | string |
| items | FoodItem[] |
| images | string[] |
| completed | boolean |
| macros | Macros |

FoodItem
| columnName | data type |
| --- | --- |
| food | string |
| amount | string |
| isFlexible | boolean |
| protein | number |
| carbs | number |
| fat | number |
| calories | number |
| isCustomInput | boolean |

Macros
| columnName | data type |
| --- | --- |
| protein | number |
| carbs | number |
| fat | number |
| calories | number |
| water | number |

### supplement_plan
| columnName | data type |
| --- | --- |
| _id | string |
| name | string |
| description | string |
| cyclePattern | string |
| days | SupplementDay[] |
| ownerId | string |
| studentIds | string[] |
| isTemplate | boolean |
| createdAt | number |
| updatedAt | number |

SupplementDay
| columnName | data type |
| --- | --- |
| day | number |
| type | string |
| name | string |
| supplements | Supplement[] |
| completed | boolean |

Supplement
| columnName | data type |
| --- | --- |
| name | string |
| timing | string |
| amount | string |
| note | string |

### daily_training
| columnName | data type |
| --- | --- |
| _id | string |
| studentID | string |
| coachID | string |
| date | string |
| planSelection | TrainingDaySelection |
| exercises | StudentExercise[] |
| diet | StudentDiet |
| supplements | StudentSupplement[] |
| bodyStats | BodyStatsRecord |
| completionStatus | string |
| coachFeedback | string |
| studentFeedback | string |
| isReviewed | boolean |
| name | string |

TrainingDaySelection
| columnName | data type |
| --- | --- |
| exercisePlanId | string |
| exerciseDayNumber | number |
| dietPlanId | string |
| dietDayNumber | number |
| supplementPlanId | string |
| supplementDayNumber | number |

StudentExercise
| columnName | data type |
| --- | --- |
| name | string |
| note | string |
| type | "strength" | "cardio" |
| sets | TrainingSet[] |
| completed | boolean |
| coachFeedback | string |
| studentFeedback | string |
| videos | string[] |
| voiceFeedbacks | VoiceFeedback[] |

VoiceFeedback
| columnName | data type |
| --- | --- |
| id | string |
| filePath | string |
| duration | number |
| uploadTime | number |
| formatTime | string |
| tempUrl | string |

StudentDiet
| columnName | data type |
| --- | --- |
| macros | Macros | null |
| meals | Meal[] |
| studentFeedback | string |
| coachFeedback | string |

StudentSupplement
| columnName | data type |
| --- | --- |
| name | string |
| timing | string |
| amount | string |
| note | string |
| taken | boolean |
| takenAt | number |

BodyStatsRecord
| columnName | data type |
| --- | --- |
| weight | number |
| createdAt | number |
| photo | string |
| note | string |

### exercise_f (exercise feedback)
| columnName | data type |
| --- | --- |
| _id | string |
| exercisePlanId | string |
| exerciseIndex | number |
| exerciseName | string |
| studentId | string |
| coachId | string |
| trainingDate | string |
| messages | FeedbackMessage[] |
| createTime | Date |
| updateTime | Date |

FeedbackMessage
| columnName | data type |
| --- | --- |
| id | string |
| type | "text" | "voice" | "image" | "video" |
| content | string |
| timestamp | number |
| duration | number |
| status | "sending" | "sent" | "failed" |
| senderId | string |

### course_schedule（单表：时间段/时间区间/预约/备忘录）
| columnName | data type |
| --- | --- |
| _id | string |
| coachId | string |
| studentId | string |
| startTime | number |
| endTime | number |
| status | "available" | "booked" | "available_range" |
| type | "time_slot" | "time_range" | "booking" | "memo" |
| createdAt | number |
| updatedAt | number |
| coachName | string |
| studentName | string |
| studentNote | string |
| coachNote | string |
| isRecurring | boolean |
| dayOfWeek | number |
| description | string |
| isTemporary | boolean |
| timeRangeId | string |
| duration | number |

### invitation_c
| columnName | data type |
| --- | --- |
| _id | string |
| invitation_code | string |
| type | number |
| is_used | boolean |
| used_by | string |
| created_by | string |
| created_at | string |
| total_days | number |

### food_library
| columnName | data type |
| --- | --- |
| _id | string |
| name | string |
| protein | number |
| carbs | number |
| fat | number |
| calories | number |
| ownerId | string |
| imageUrl | string |
| createdAt | number |
| updatedAt | number |

### body_measure
| columnName | data type |
| --- | --- |
| _id | string |
| studentID | string |
| createdAt | number |
| recordDate | string |
| weight | number |
| measurements | object<string, number> |
| photos | string[] |

### plan（如仍在使用，用于模板列表）
| columnName | data type |
| --- | --- |
| _id | string |
| name | string |
| student_ids | string[] |
| cycle_pattern | string |
| created_by | string |


## Pages and API Usage

| Page | Role | Purpose | Services | Cloud Functions |
| --- | --- | --- | --- | --- |
| `pages/coachX/coachX` | coach-only | 教练首页统计/概览 | `CoachService.getStudentsStats` | `fetchStudentsStats` |
| `pages/students/students` | coach-only | 学员列表与分页 | `FetchStudentsService.fetchStudents` | `fetchStudents` |
| `pages/trainingPlanList/trainingPlanList` | coach-only | 教练计划列表与分配 | `ExercisePlanService.listPlans`, `DietPlanService.listPlans`, `SupplementPlanService.listPlans`, `ExercisePlanService.assignToStudent`, `DietPlanService.assignToStudent`, `SupplementPlanService.assignToStudent` | `exercisePlan`(list), `dietPlan`(list), `supplementPlan`(list), `assignPlan`(assign/unassign) |
| `pages/exercisePlan/exercisePlan` | coach-only | 动作计划编辑/AI/分配 | `ExercisePlanService.{createPlan,updatePlan,deletePlan,getPlan,copyPlan}` | `exercisePlan`(CRUD+copy), `assignPlan`, `generateAITrainingPlan` |
| `pages/dietPlan/dietPlan` | coach-only | 饮食计划编辑/食物库/分配 | `DietPlanService.{createPlan,updatePlan,deletePlan,getPlan,copyPlan}` | `dietPlan`(CRUD+copy), `assignPlan`, `foodLibrary`(list/search/create/update/delete), `generateAITrainingPlan` |
| `pages/supplementPlan/supplementPlan` | coach-only | 补剂计划编辑/分配 | `SupplementPlanService.{createPlan,updatePlan,deletePlan,getPlan,copyPlan}` | `supplementPlan`(CRUD+copy), `assignPlan`, `generateAITrainingPlan` |
| `pages/coachSchedule/coachSchedule` | coach-only | 教练周视图/时间区间/预约 | `CourseBookingService.{fetchCoachTimeRanges,fetchCoachMemos,fetchCoachBookings,createTimeRange,deleteTimeRange,createCourseBooking}`, `CoachService.{updateTimeSlotNote,deleteBooking}` | `fetchCoachAvailableSlots`, `createCoachAvailableSlots`, `updateTimeSlot`, `deleteTimeSlot`, `createCourseBooking`, `fetchCoachBookings` |
| `pages/overview/overview` | student-only | 学生首页：计划+今日/最近训练 | `PlanOverviewService.getStudentPlans`, `getLatestDailyTraining` | `getStudentPlans`, `fetchLatestTraining` |
| `pages/student/training/training` | student-only | 今日训练查看/提交 | `getTodayTrainingData`, `saveDailyTraining`, `ExerciseFeedbackService.{getCurrentFeedback,saveFeedbackMessage,getHistoryFeedback}` | `fetchTodayTraining`, `upsertTodayTraining`, `getExerciseFeedback`, `upsertExerciseFeedback`, `getExerciseHistoryFeedback` |
| `pages/student/data/data` | student-only | 身体测量列表/增删 | `getMeasurementSessions`, `saveMeasurementSession`, `deleteMeasurementSession` | `fetchMeasurementSessions`, `saveMeasurementSession`, `deleteMeasurementSession` |
| `pages/student/trainingHistory/trainingHistory` | student-only | 训练历史列表 | `getTrainingHistory` | `fetchTrainingHistory` |
| `pages/trainingDetail/trainingDetail` | both | 训练详情 | `getTodayTrainingData`, `getLatestDailyTraining` | `fetchTodayTraining`, `fetchLatestTraining` |
| `pages/exerciseDetail/exerciseDetail` | both | 动作反馈详情/消息 | `ExerciseFeedbackService.{getCurrentFeedback,saveFeedbackMessage,getHistoryFeedback}` | `getExerciseFeedback`, `upsertExerciseFeedback`, `getExerciseHistoryFeedback` |
| `pages/profile/profile` | both | 个人信息查看/更新 | `UserService.{fetchUserInfoWithoutUserID,updateUserInfo}` | `fetchUserInfo`, `updateUserInfo` |
| `pages/login/login` | both | 登录与邀请码验证 | `UserService.login` | `login`, `verifyInvitationCode` |
| `pages/privacyPolicy/privacyPolicy` | both | 隐私政策 | - | - |
| `pages/studentPages/profileSetup/profileSetup` | student-only | 学生资料初始化 | `UserService.{fetchUserInfoWithoutUserID,updateUserInfo}` | `fetchUserInfo`, `updateUserInfo` |
| `pages/studentPages/studentDetail/studentDetail` | coach-only | 学员详情（教练视角） | `UserService.fetchUserInfo`, `PlanOverviewService.getStudentPlans` | `fetchUserInfo`, `getStudentPlans` |

说明：
- AI 生成：含 AI 能力的页面调用 `generateAITrainingPlan`，`activeTab` 控制输出段（exercises / diet / supplements）。
- 食物库：饮食计划页内使用 `foodLibrary` 的 `list/search/create/update/delete`，支持公共与私有库（`ownerId` 为空串表示公共）。


