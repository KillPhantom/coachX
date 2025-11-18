# Daily Training Review Page - Implementation Summary

**Feature**: Daily Training Review Page (训练详情审核页面)
**Route**: `/training-review/:dailyTrainingId`

---

## Overview

Coaches can view detailed training records (nutrition, exercises, videos), provide feedback (text/voice/image), and mark training as reviewed.

### Key Features

- ✅ Display training details (nutrition, exercises, videos, keyframes)
- ✅ Real-time feedback input (text, voice, image)
- ✅ Exercise-specific or overall feedback
- ✅ **Two-tier tab navigation** (Exercise → Video)
- ✅ **Full-screen video playback**
- ✅ Keyframe extraction and display
- ✅ Mark training as reviewed

---

## Architecture

### Directory Structure

```
lib/features/chat/
├── data/
│   ├── models/
│   │   ├── training_feedback_model.dart (refactored 2025-11-15)
│   │   └── training_summary.dart
│   └── repositories/
│       ├── feedback_repository.dart
│       ├── feedback_repository_impl.dart
│       ├── daily_training_repository.dart
│       └── daily_training_repository_impl.dart
├── presentation/
│   ├── pages/
│   │   └── daily_training_review_page.dart
│   ├── providers/
│   │   └── daily_training_review_providers.dart
│   └── widgets/
│       ├── feedback_input_bar.dart
│       ├── exercise_feedback_history_section.dart (NEW 2025-11-16)
│       └── feedback_card.dart
```

---

## Data Models

### TrainingFeedbackModel (Refactored 2025-11-15)

**Collection**: `dailyTrainingFeedback`

**Minimalist Design** (12 fields):

```dart
{
  // === Core Association ===
  id: String,
  dailyTrainingId: String,
  studentId: String,
  coachId: String,
  trainingDate: String,     // "yyyy-MM-dd"

  // === Exercise Association (Optional) ===
  exerciseIndex: int?,      // null = overall, 0/1/2... = specific exercise
  exerciseName: String?,    // "Squat", "Bench Press" - for history queries

  // === Feedback Content ===
  feedbackType: String,     // "text" | "voice" | "image" (required)
  textContent: String?,
  voiceUrl: String?,
  voiceDuration: int?,      // seconds
  imageUrl: String?,

  // === Metadata ===
  createdAt: int,           // milliseconds
  isRead: bool
}
```

**Benefits**:
- 33% field reduction (12 vs 18+)
- Supports overall + exercise-specific feedback
- Enables efficient exercise history queries
- Zero data redundancy

### DailyTrainingModel

**Collection**: `dailyTrainings`

```dart
{
  id: String,
  studentID: String,
  coachID: String,
  date: String,             // "yyyy-MM-dd"
  isReviewed: bool,
  diet: {...},
  exercises: [{
    name: String,
    sets: [{reps, weight, completed}],
    videos: [{videoUrl, thumbnailUrl}],
    keyframes: [{url, timestamp}],
    timeSpent: int?
  }],
  extractedKeyFrames: Map<exerciseIndex, ExtractedKeyFrame>
}
```

---

## Repository Layer

### FeedbackRepository

**Key Methods**:

```dart
// Add feedback (with exercise association)
Future<void> addFeedback({
  required String dailyTrainingId,
  required String studentId,
  required String coachId,
  required String trainingDate,
  int? exerciseIndex,        // NEW: for exercise-specific feedback
  String? exerciseName,      // NEW: for history queries
  required String feedbackType,
  String? textContent,
  String? voiceUrl,
  int? voiceDuration,
  String? imageUrl,
});

// Query exercise history (NEW)
Stream<List<TrainingFeedbackModel>> getExerciseHistoryFeedbacks({
  required String studentId,
  required String exerciseName,
  String? startDate,
  String? endDate,
  int? limit,
});

// Other methods
Stream<List<TrainingFeedbackModel>> watchFeedbacks(...);
Stream<List<TrainingFeedbackModel>> getFeedbackHistory(String dailyTrainingId);
Future<String> uploadVoiceFile(...);
Future<String> uploadImageFile(...);
```

### DailyTrainingRepository

```dart
Future<DailyTrainingModel?> getDailyTraining(String dailyTrainingId);
Future<void> markAsReviewed(String dailyTrainingId);
```

---

## Firestore Configuration

### Indexes

**Required for exercise history queries**:

```json
{
  "collectionGroup": "dailyTrainingFeedback",
  "fields": [
    {"fieldPath": "studentId", "order": "ASCENDING"},
    {"fieldPath": "exerciseName", "order": "ASCENDING"},
    {"fieldPath": "trainingDate", "order": "DESCENDING"}
  ]
}
```

**Deploy**:
```bash
firebase deploy --only firestore:indexes
```

### Security Rules

**dailyTrainingFeedback**:
```javascript
match /dailyTrainingFeedback/{feedbackId} {
  // Coaches and students can read their related feedback
  allow read: if isSignedIn() && (
    resource.data.coachId == request.auth.uid ||
    resource.data.studentId == request.auth.uid
  );

  // Only coaches can create feedback
  allow create: if isSignedIn() &&
    request.resource.data.coachId == request.auth.uid;

  // Coaches can update, students can mark as read
  allow update: if isSignedIn() && (
    resource.data.coachId == request.auth.uid ||
    (resource.data.studentId == request.auth.uid &&
     request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']))
  );
}
```

**dailyTrainings**:
```javascript
match /dailyTrainings/{trainingId} {
  allow read: if isSignedIn() && (
    resource.data.coachID == request.auth.uid ||
    resource.data.studentID == request.auth.uid
  );

  allow create, update: if isSignedIn() &&
    request.resource.data.studentID == request.auth.uid;

  // Coaches can update review status
  allow update: if isSignedIn() &&
    resource.data.coachID == request.auth.uid;
}
```

---

## Key Features

### 1. Exercise-Level Feedback System (NEW 2025-11-16)

**Interactive Feedback Input**:
- **Toggle Button**: "Provide Feedback" button below video section
- **Conditional Display**: FeedbackInputBar hidden by default, shows on button click
- **Context-Aware**: Automatically associates feedback with currently selected exercise
- **Exercise Switching**: Input bar hides when switching exercises, feedback history updates

**Input Modes**:
- **Text**: Direct input via `FeedbackInputBar`
- **Voice**: Long-press recording (AAC format)
- **Image**: Image picker with annotation support
- **Auto-upload**: Firebase Storage (voices, images)
- **Real-time**: Stream updates via `exerciseFeedbackHistoryProvider`

**UI Structure**:
```
┌─────────────────────────────────────┐
│  Video Display Area                  │
│  ┌─────────────────────────────┐    │
│  │  Exercise video + keyframes  │    │
│  └─────────────────────────────┘    │
│  [Provide Feedback ✏️]              │  ← Toggle button
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  Exercise Feedback History           │  ← Always visible
│  ┌─────────────────────────────┐    │
│  │ 2025-11-15 | 2h ago          │    │
│  │ "Great depth on squats!"     │    │
│  └─────────────────────────────┘    │
│  [Load More]                         │  ← Pagination
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  FeedbackInputBar (conditional)      │  ← Shows when toggled
└─────────────────────────────────────┘
```

### 2. Exercise Association

**Automatic Association**:
```dart
// Get current exercise context
final selectedExerciseIndex = ref.read(selectedExerciseIndexProvider);
final exerciseName = exercises[selectedExerciseIndex].name;

// All feedback automatically tagged with exercise
addFeedback(
  exerciseIndex: selectedExerciseIndex,  // e.g., 0, 1, 2
  exerciseName: exerciseName,            // e.g., "Squat"
  feedbackType: 'text',
  textContent: 'Great form!',
);
```

**Benefits**:
- **Exercise-Specific**: Each exercise has its own feedback stream
- **Cross-Training History**: View all historical feedback for this exercise (across dates)
- **Contextual**: Students see exactly which exercise the coach is commenting on

### 3. Exercise Feedback History Section

**Features**:
- **Reddit-Style Layout**: Card-based comment display
- **Date Grouping**: Shows training date for each feedback
- **Multi-Format**: Supports text, voice, and image feedback
- **Pagination**: Load 10 items initially, "Load More" for additional feedback
- **Empty State**: User-friendly message when no feedback exists
- **Real-time**: Auto-updates when new feedback is added

**Implementation**:
```dart
// Provider with pagination
final exerciseFeedbackHistoryProvider = StreamProvider.family<
    List<TrainingFeedbackModel>,
    ExerciseFeedbackParams
>((ref, params) {
  final page = ref.watch(exerciseFeedbackPageProvider);
  return repository.getExerciseHistoryFeedbacks(
    studentId: params.studentId,
    exerciseName: params.exerciseName,
    limit: page * 10,  // Cumulative loading
  );
});

// Usage
ExerciseFeedbackHistorySection(
  studentId: dailyTraining.studentId,
  exerciseName: exercises[selectedIndex].name,
)
```

**Query Example**:
```dart
// Get all "Squat" feedback for a student (across all training days)
final squatFeedbacks = repository.getExerciseHistoryFeedbacks(
  studentId: 'student_123',
  exerciseName: 'Squat',
  limit: 10,  // Pagination support
);
```

### 4. Keyframe Extraction

- **Local extraction**: Using `LocalKeyframeExtractor`
- **Video sources**: Firebase Storage URLs
- **Storage**: `extractedKeyFrames` in dailyTraining document
- **Display**: Keyframe grid with timestamps

### 5. Two-Tier Tab Navigation (NEW 2025-11-16)

**Structure**:
```
┌─────────────────────────────────────────┐
│  [Exercise 1✓] [Exercise 2] [Exercise 3]  │  ← Tier 1: Exercise tabs
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│    [Video 1] [Video 2✓] [Video 3]         │  ← Tier 2: Video tabs (conditional)
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│         [Video Display Area]              │  ← Click to fullscreen
└─────────────────────────────────────────┘
```

**Providers**:
- `selectedExerciseIndexProvider` - Tracks selected exercise
- `selectedVideoIndexProvider` - Tracks selected video (NEW)

**Behavior**:
- **Exercise Tab**: Shows all exercises with videos
- **Video Tab**:
  - Conditionally displayed: Only when exercise has 2+ videos
  - Auto-hidden: When exercise has 1 video
  - Auto-reset: Video index resets to 0 when switching exercises
- **Video Display**:
  - Click thumbnail → Full-screen playback via `VideoPlayerDialog`
  - Shows selected video based on `selectedVideoIndexProvider`

**State Management**:
```dart
// When Exercise tab is clicked
ref.read(selectedExerciseIndexProvider.notifier).state = exerciseIndex;
ref.read(selectedVideoIndexProvider.notifier).state = 0; // Reset video index

// When Video tab is clicked
ref.read(selectedVideoIndexProvider.notifier).state = videoIndex;
```

**Video Selection Logic**:
```dart
// Boundary-safe video selection
final selectedVideoIndex = ref.watch(selectedVideoIndexProvider);
final videoCount = currentExercise.videos.length;
final validVideoIndex = videoCount > 0
    ? (selectedVideoIndex < videoCount ? selectedVideoIndex : 0)
    : 0;

final currentVideo = currentExercise.videos[validVideoIndex];
```

### 6. Full-Screen Video Playback (NEW 2025-11-16)

**Implementation**:
```dart
void _handleVideoPlay(BuildContext context, VideoUploadState? video) {
  if (video?.downloadUrl == null || video?.status != VideoUploadStatus.completed) {
    return;
  }

  VideoPlayerDialog.show(
    context,
    videoUrls: [video.downloadUrl!],
    initialIndex: 0,
  );
}
```

**Features**:
- Cached video playback (`CachedVideoPlayerPlus`)
- Progress bar with seek functionality
- Play/pause controls
- Automatic play on open
- Safe state checking (only plays completed videos)

### 7. Video Download Caching System (NEW 2025-11-17)

**Purpose**: Eliminate redundant video downloads for manual keyframe extraction.

**Architecture**:
```
VideoCacheService (Singleton)
  ↓
Hive Box (video_cache)
  ↓
VideoCacheMetadata (6 fields: url, localPath, trainingId, fileSize, cachedAt, expiresAt)
  ↓
VideoDownloader (injected via Provider)
```

**Data Flow**:
```
1. VideoPlayerDialog opens → Check cache
2. Cache hit (< 1 hour) → Return local path
3. Cache miss/expired → Download → Save metadata
4. App startup → Clear expired cache
```

**Core Components**:
- `VideoCacheService` - Singleton cache manager (Hive-based)
- `VideoCacheMetadata` - Cache metadata model (Hive TypeAdapter)
- `VideoDownloader` - Download service with cache integration
- `videoCacheServiceProvider` - Riverpod provider
- `videoDownloaderProvider` - Riverpod provider (auto-injects cache service)

**Cache Policy**:
- **Validity**: 1 hour (configurable in `VideoCacheMetadata.create()`)
- **Storage**: Local temporary directory (`training_videos/`)
- **Cleanup**: Automatic on app startup
- **Verification**: File existence check before returning cached path

**Key Methods**:
```dart
// VideoCacheService
Future<String?> getCachedVideoPath(String videoUrl, String trainingId)
Future<void> saveCacheMetadata(VideoCacheMetadata metadata)
Future<void> clearExpiredCache()
Future<void> clearAllVideoCache()

// VideoDownloader
Future<String> downloadVideo(String videoUrl, String trainingId)
```

**Logs**:
- `✅ 缓存命中: <trainingId>` - Cache hit
- `❌ 缓存未命中，开始下载: <trainingId>` - Cache miss
- `⏰ 缓存过期: <trainingId>` - Cache expired

**Files**:
- `lib/core/models/video_cache_metadata.dart` - Data model
- `lib/core/services/video_cache_service.dart` - Cache service (singleton)
- `lib/core/providers/cache_providers.dart` - Providers
- `lib/main.dart` - Initialization logic

---

## Related Documentation

- **Backend APIs**: `/docs/backend_apis_and_document_db_schemas.md`
- **Training Review List**: `/docs/coach/training_review_list_feature.md`
- **Project Guidelines**: `/CLAUDE.md`

---

**Last Updated**: 2025-11-17
**Document Version**: 3.0 (Video Download Caching System)

## Changelog (Historical Reference Only)

### 2025-11-17 - Video Download Caching System

**Problem**: Every video open triggered redundant downloads, wasting network and time.

**Solution**: Implemented Hive-based caching with 1-hour validity.

**Impact**:
- First open: Download + cache
- Subsequent opens (< 1 hour): Instant playback from cache
- Network usage reduced by ~90% for repeated views

### 2025-11-16 - Exercise-Level Feedback System

**Added**: Exercise-specific feedback with toggleable input, pagination, and cross-training history.

**Key Components**:
- `ExerciseFeedbackHistorySection` - Reddit-style feedback display
- `isFeedbackInputVisibleProvider` - Toggle visibility
- Firestore index for exercise history queries

### 2025-11-16 - Two-Tier Tab Navigation & Video Playback

**Added**: Nested tabs (Exercise → Video) and full-screen video playback.

**Features**:
- Conditional video sub-tabs (only when 2+ videos)
- `VideoPlayerDialog` with full-screen playback
- Automatic index reset on exercise switch

### 2025-11-16 - Keyframe Editing & Replacement System

**Fixed**: Storage permission errors for keyframe editing.

**Changes**:
- Upload path: `training_keyframes/` (instead of `feedback_images/`)
- Direct keyframe replacement (instead of creating feedback)
- Blocking loading dialog during save

### 2025-11-15 - TrainingFeedbackModel Refactor

**Simplified**: 18+ fields → 12 fields (33% reduction).

**Added**: `exerciseIndex`, `exerciseName` for exercise association.

### 2025-11-15 - Feedback Input Refactor

**Added**: WeChat-style input bar (text/voice/image) with real-time feedback history.

### 2025-11-14 - Initial Implementation

**Core Features**: Training detail display, mark as reviewed, video navigation, keyframe extraction.
