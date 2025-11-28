## Backend APIs (Cloud Functions)

Google docs: https://docs.google.com/document/d/1yKQgZWjdeALkwrl2SHf6RjUnsCmeLxtoWFrv0Epr7SQ/edit?tab=t.9cl42i828p31

- 用户
  - fetchUserInfo(userId?)
  - login(userInfo)
  - updateUserInfo(name?, avatarUrl?, role?, gender?, bornDate?, height?, initialWeight?, coachId?, activeExercisePlanId?, activeDietPlanId?, activeSupplementPlanId?)
  - updateActivePlan(planType, planId)

- 学员与统计
  - fetchStudents(pageSize?, pageNumber?, otherParams?)
  - fetchStudentsStats()
  - fetchStudentDetail(studentId, timeRange?)

- 计划 CRUD 与分配
  - exercisePlan: action in [create | update | delete | get | list | copy]
  - dietPlan: action in [create | update | delete | get | list | copy]
  - supplementPlan: action in [create | update | delete | get | list | copy]
  - assignPlan: action in [assign | unassign] with { planType, planId, studentId }
  - getStudentAssignedPlans() - 获取分配给学生的计划（每类返回最新一个）
  - getStudentAllPlans() - 获取学生所有可见计划（教练分配 + 自己创建）

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

- 训练反馈
  - fetchStudentFeedback(studentId, coachId, startDate?, endDate?, limit?)

- 身体测量
  - saveMeasurementSession(session)
  - deleteMeasurementSession(sessionId)
  - fetchMeasurementSessions(studentID, startDate?, endDate?)


- 食物库
  - foodLibrary: action in [create | update | delete | get | list | search]

- 动作库
  - exerciseTemplate: action in [create | update | delete | get | list]
  - deleteExerciseTemplate(templateId) - Checks if template is used in any plans before deletion

- 邀请码
  - fetchInvitationCode()
  - verifyInvitationCode(code)
  - generateInvitationCodes(codeCount?, codeType?)
  - generateStudentInvitationCode(totalDays?)

- AI 生成
  - generateAITrainingPlan(prompt, dayIndex?, activeTab?)

- 聊天消息
  - sendMessage(conversationId, senderId, receiverId, type, content, mediaUrl?, mediaMetadata?)
  - fetchMessages(conversationId, limit?, beforeTimestamp?)
  - markMessagesAsRead(conversationId, userId, lastReadTimestamp)
  - getOrCreateConversation(coachId, studentId)


## Database Schemas (Document Database)

### users
| columnName | data type |
| --- | --- |
| id | string |
| role | string |
| name | string |
| email | string |
| avatarUrl | string |
| gender | string |
| coachId | string |
| isVerified | boolean |
| bornDate | string |
| height | number |
| initialWeight | number |
| activeExercisePlanId | string (optional) |
| activeDietPlanId | string (optional) |
| activeSupplementPlanId | string (optional) |
| createdAt | timestamp |
| updatedAt | timestamp |

### exercisePlan
| columnName | data type |
| --- | --- |
| id | string |
| name | string |
| description | string |
| cyclePattern | string |
| days | ExerciseTrainingDay[] |
| ownerId | string |
| studentIds | string[] |
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
| exerciseTemplateId | string (optional) |

**Notes**:
- `exerciseTemplateId`: Links to an ExerciseTemplate in the exercise library. If set, the exercise references a template for guidance (videos, images, text).
- Removed fields: `completed`, `detailGuide`, `demoVideos` (moved to ExerciseTemplate)

TrainingSet
| columnName | data type |
| --- | --- |
| reps | string |
| weight | string |
| completed | boolean |

### exerciseTemplates
| columnName | data type |
| --- | --- |
| id | string |
| ownerId | string |
| name | string |
| tags | string[] |
| textGuidance | string (optional) |
| imageUrls | string[] |
| videoUrls | string[] |
| thumbnailUrls | string[] |
| createdAt | timestamp |
| updatedAt | timestamp |

**Notes**:
- `ownerId`: The coach who created this template. Templates are private to each coach.
- `tags`: Categorization tags (e.g., "chest", "compound", "beginner"). Used for searching and filtering.
- `textGuidance`: Detailed instructions on how to perform the exercise.
- `imageUrls`: Reference images showing proper form (max 5 images).
- `videoUrls`: Demonstration videos. Multiple videos can be uploaded.
- `thumbnailUrls`: Corresponding thumbnails for each video. Same array length as videoUrls.
- Referenced by Exercise.exerciseTemplateId and StudentExercise.exerciseTemplateId

### dietPlan
| columnName | data type |
| --- | --- |
| id | string |
| name | string |
| description | string |
| cyclePattern | string |
| days | DietDay[] |
| ownerId | string |
| studentIds | string[] |
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
| macros | Macros (computed from items) |

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

### supplementPlan
| columnName | data type |
| --- | --- |
| id | string |
| name | string |
| description | string |
| cyclePattern | string |
| days | SupplementDay[] |
| ownerId | string |
| studentIds | string[] |
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

### dailyTrainings
| columnName | data type |
| --- | --- |
| id | string |
| studentID | string |
| coachID | string |
| date | string |
| planSelection | TrainingDaySelection |
| exercises | StudentExercise[] |
| diet | StudentDiet |
| supplements | StudentSupplement[] |
| completionStatus | string |
| isReviewed | boolean |
| totalDuration | number (optional) |
| extractedKeyFrames | Map<string, ExtractedKeyFrame> |

**Notes**:
- `totalDuration` is the total training session duration in seconds, measured from when the timer starts to when the last exercise is completed. Only saved when all exercises are completed and the timer was started.
- `extractedKeyFrames` stores extracted keyframes separately from exercise data, using exercise index as key (e.g., "0", "1").

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
| videos | VideoRecord[] |
| voiceFeedbacks | VoiceFeedback[] |
| timeSpent | number (optional) |
| exerciseTemplateId | string (optional) |

**Notes**:
- `exerciseTemplateId`: Links to an ExerciseTemplate. Copied from the Exercise in the training plan. Used to display exercise guidance (videos, images, text) in the student app.
- `timeSpent` is the duration in seconds for completing this specific exercise. Calculated from the time the user starts editing sets to when all sets are marked as completed.

VideoRecord
| columnName | data type |
| --- | --- |
| videoUrl | string |
| thumbnailUrl | string |

**Note**: `VideoRecord` contains both video and thumbnail URLs. The thumbnail is uploaded alongside the video to improve loading performance.

VoiceFeedback
| columnName | data type |
| --- | --- |
| id | string |
| filePath | string |
| duration | number |
| uploadTime | number |
| formatTime | string |
| tempUrl | string |

ExtractedKeyFrame
| columnName | data type | description |
| --- | --- | --- |
| exerciseName | string | 动作名称 |
| keyframes | KeyframeData[] | 关键帧列表 |
| method | string | 提取方法（"mediapipe_pose" 或 "uniform_sampling"） |

**Note**: `ExtractedKeyFrame` stores keyframes extracted from exercise videos using AI pose detection or uniform sampling. The `method` field indicates which extraction algorithm was used.

KeyframeData
| columnName | data type | description |
| --- | --- | --- |
| url | string | 关键帧图片 URL（Firebase Storage） |
| timestamp | float | 视频中的时间戳（秒） |

**Note**: `KeyframeData` contains both the image URL and the timestamp in the source video where the keyframe was extracted.

StudentDiet
| columnName | data type |
| --- | --- |
| meals | Meal[] |
| coachFeedback | string |

**Note**: `macros` is computed from all meals' macros (sum of items). `studentFeedback` has been removed.

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

### exerciseFeedBack
| columnName | data type |
| --- | --- |
| id | string |
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


### dailyTrainingFeedback (Updated 2025-11-15)
| columnName | data type | description |
| --- | --- | --- |
| id | string | Feedback ID |
| dailyTrainingId | string | Link to dailyTraining record |
| studentId | string | Student ID |
| coachId | string | Coach ID |
| trainingDate | string | Training date "yyyy-MM-dd" |
| **exerciseIndex** | **number \| null** | **NEW: null = overall feedback, 0/1/2... = specific exercise** |
| **exerciseName** | **string \| null** | **NEW: Exercise name for history queries (e.g., "Squat")** |
| feedbackType | string | "text" \| "voice" \| "image" (required) |
| textContent | string \| null | Text feedback content |
| voiceUrl | string \| null | Voice file URL |
| voiceDuration | number \| null | Voice duration in seconds |
| imageUrl | string \| null | Image URL |
| createdAt | timestamp | Creation time (milliseconds) |
| isRead | boolean | Student has read |

**Removed Fields** (for minimalism):
- ❌ `trainingSummary` - Now calculated from dailyTraining in real-time
- ❌ `exerciseFeedback`, `dietFeedback`, `overallFeedback` - Unified to new format
- ❌ `updatedAt` - Feedback is immutable


### invitationCodes
| columnName | data type |
| --- | --- |
| id | string |
| code | string |
| coachId | string |
| used | boolean |
| usedBy | string |
| createdAt | timestamp |
| expiresAt | timestamp |

### foodLibrary
| columnName | data type |
| --- | --- |
| id | string |
| name | string |
| protein | number |
| carbs | number |
| fat | number |
| calories | number |
| ownerId | string |
| imageUrl | string |
| createdAt | number |
| updatedAt | number |

### bodyMeasure
| columnName | data type |
| --- | --- |
| id | string |
| studentID | string |
| createdAt | number |
| recordDate | string |
| weight | number |
| measurements | json |
| photos | string[] |

### conversations
| columnName | data type |
| --- | --- |
| id | string |
| coachId | string |
| studentId | string |
| lastMessage | LastMessage |
| lastMessageTime | number |
| coachUnreadCount | number |
| studentUnreadCount | number |
| coachLastReadTime | number |
| studentLastReadTime | number |
| participantNames | ParticipantNames |
| participantAvatars | ParticipantAvatars |
| isArchived | boolean |
| isPinned | boolean |
| createdAt | timestamp |
| updatedAt | timestamp |

LastMessage
| columnName | data type |
| --- | --- |
| id | string |
| content | string |
| type | "text" \| "image" \| "video" \| "voice" |
| senderId | string |
| timestamp | number |
| mediaUrl | string |

ParticipantNames
| columnName | data type |
| --- | --- |
| coachName | string |
| studentName | string |

ParticipantAvatars
| columnName | data type |
| --- | --- |
| coachAvatarUrl | string |
| studentAvatarUrl | string |

### messages
| columnName | data type |
| --- | --- |
| id | string |
| conversationId | string |
| senderId | string |
| receiverId | string |
| type | "text" \| "image" \| "video" \| "voice" |
| content | string |
| mediaUrl | string |
| mediaMetadata | MessageMetadata |
| status | "sending" \| "sent" \| "delivered" \| "read" \| "failed" |
| isDeleted | boolean |
| createdAt | timestamp |
| readAt | timestamp |

MessageMetadata
| columnName | data type |
| --- | --- |
| fileName | string |
| fileSize | number |
| duration | number |
| width | number |
| height | number |
| thumbnailUrl | string |


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
| `pages/studentPages/studentDetail/studentDetail` | coach-only | 学员详情（教练视角） | `StudentDetailService.fetchStudentDetail` | `fetchStudentDetail` |
| `pages/chat/chatList` | both | 对话列表 | `ChatRepository.watchConversations` | Firestore实时监听 |
| `pages/chat/chatDetail` | both | 对话详情/发送消息 | `ChatRepository.{watchMessages,sendMessage,markMessagesAsRead}` | `sendMessage`, `fetchMessages`, `markMessagesAsRead` |

说明：
- AI 生成：含 AI 能力的页面调用 `generateAITrainingPlan`，`activeTab` 控制输出段（exercises / diet / supplements）。
- 食物库：饮食计划页内使用 `foodLibrary` 的 `list/search/create/update/delete`，支持公共与私有库（`ownerId` 为空串表示公共）。


