"""
Firestore Triggers for Notifications
"""

from firebase_functions import firestore_fn, options
from firebase_admin import firestore
from .utils import get_user_fcm_token, send_fcm_notification
from utils import logger
from typing import Dict, Any

@firestore_fn.on_document_created(document="messages/{messageId}")
def on_message_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """
    Trigger: When a new message is created.
    Sends a notification to the receiver.
    """
    try:
        snapshot = event.data
        if not snapshot:
            return

        message_data = snapshot.to_dict()
        sender_id = message_data.get('senderId')
        receiver_id = message_data.get('receiverId')
        content = message_data.get('content')
        message_type = message_data.get('type')
        
        # Don't notify for own messages (though trigger shouldn't matter much)
        if not receiver_id or not sender_id:
            return

        # Fetch sender name for better notification
        db = firestore.client()
        sender_doc = db.collection('users').document(sender_id).get()
        sender_name = "Someone"
        if sender_doc.exists:
            sender_info = sender_doc.to_dict()
            sender_name = sender_info.get('displayName') or "User"

        # Determine body text based on type
        body_text = content
        if message_type == 'image':
            body_text = '[Image]'
        elif message_type == 'video':
            body_text = '[Video]'
        elif message_type == 'voice':
            body_text = '[Voice Message]'

        token = get_user_fcm_token(receiver_id)
        if token:
            send_fcm_notification(
                token=token,
                title=f"New message from {sender_name}",
                body=body_text,
                data={
                    "type": "chat_message",
                    "conversationId": message_data.get('conversationId'),
                    "senderId": sender_id
                }
            )
            logger.info(f"Notification sent to {receiver_id} for message {event.params['messageId']}")
        else:
            logger.info(f"No FCM token found for user {receiver_id}")

    except Exception as e:
        logger.error(f"Error in on_message_created: {e}")


@firestore_fn.on_document_created(document="dailyTrainings/{trainingId}")
def on_training_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """
    Trigger: When a student submits a new daily training record.
    Sends a notification to the coach.
    """
    try:
        snapshot = event.data
        if not snapshot:
            return

        training_data = snapshot.to_dict()
        student_id = training_data.get('studentID')
        coach_id = training_data.get('coachID')
        date = training_data.get('date')

        if not coach_id or not student_id:
            return

        # Fetch student name
        db = firestore.client()
        student_doc = db.collection('users').document(student_id).get()
        student_name = "Student"
        if student_doc.exists:
            student_name = student_doc.to_dict().get('displayName') or "Student"

        token = get_user_fcm_token(coach_id)
        if token:
            send_fcm_notification(
                token=token,
                title="New Training Record",
                body=f"{student_name} submitted a training for {date}",
                data={
                    "type": "new_training",
                    "studentId": student_id,
                    "trainingId": event.params['trainingId'],
                    "date": date
                }
            )
            logger.info(f"Notification sent to coach {coach_id} for training {event.params['trainingId']}")
        else:
            logger.info(f"No FCM token found for coach {coach_id}")

    except Exception as e:
        logger.error(f"Error in on_training_created: {e}")


@firestore_fn.on_document_updated(document="dailyTrainings/{trainingId}")
def on_training_updated(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Trigger: When a training record is updated (e.g., reviewed by coach).
    Sends a notification to the student if isReviewed changes to True.
    """
    try:
        change = event.data
        if not change:
            return

        before = change.before.to_dict()
        after = change.after.to_dict()

        is_reviewed_before = before.get('isReviewed', False)
        is_reviewed_after = after.get('isReviewed', False)

        # Only trigger if status changed from False to True
        if not is_reviewed_before and is_reviewed_after:
            student_id = after.get('studentID')
            date = after.get('date')
            
            if not student_id:
                return

            token = get_user_fcm_token(student_id)
            if token:
                send_fcm_notification(
                    token=token,
                    title="Training Reviewed",
                    body=f"Your coach has reviewed your training for {date}",
                    data={
                        "type": "training_reviewed",
                        "trainingId": event.params['trainingId'],
                        "date": date
                    }
                )
                logger.info(f"Notification sent to student {student_id} for review of training {event.params['trainingId']}")
            else:
                logger.info(f"No FCM token found for student {student_id}")

    except Exception as e:
        logger.error(f"Error in on_training_updated: {e}")

