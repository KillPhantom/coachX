"""
Notification Utils for FCM

Handles token fetching and message sending.
"""

from firebase_admin import messaging, firestore
from utils import logger
from typing import Optional, Dict

def get_user_fcm_token(user_id: str) -> Optional[str]:
    """
    Fetch FCM token for a user from Firestore.
    """
    try:
        db = firestore.client()
        user_doc = db.collection('users').document(user_id).get()
        if user_doc.exists:
            return user_doc.to_dict().get('fcmToken')
        return None
    except Exception as e:
        logger.error(f"Error fetching FCM token for user {user_id}: {e}")
        return None

def send_fcm_notification(
    token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> bool:
    """
    Send an FCM notification to a specific device token.
    """
    try:
        # Construct the message
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
            # Android config
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    channel_id='high_importance_channel',
                    priority='high',
                    default_sound=True,
                    default_vibrate_timings=True
                ),
            ),
            # APNs (iOS) config
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(
                            title=title,
                            body=body,
                        ),
                        badge=1,
                        sound='default',
                        content_available=True,
                    ),
                ),
            ),
        )

        # Send the message
        response = messaging.send(message)
        logger.info(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        logger.error(f"Error sending FCM message: {e}")
        return False

