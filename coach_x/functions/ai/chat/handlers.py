"""
AI Chat Handlers

Cloud Functions for AI Coach chat.
"""

from firebase_functions import https_fn, options
from firebase_admin import firestore
from flask import Response
import json
from typing import Dict, Any, Tuple, Optional, List
from datetime import datetime, timedelta

from utils.logger import logger
from ..memory_manager import MemoryManager
from .streaming import stream_chat_with_ai

@https_fn.on_request(
    timeout_sec=540,
    secrets=["ANTHROPIC_API_KEY"],
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post", "options"]),
)
def chat_with_ai(req: https_fn.Request) -> Response:
    """
    Chat with AI Coach (SSE)
    
    HTTP POST /chat_with_ai
    
    Body:
    {
        "user_id": str,
        "message": str
    }
    
    Response: SSE stream
    """
    try:
        logger.info("💬 [Chat] Received chat request")
        
        # Parse request
        try:
            data = req.get_json()
            if not data:
                raise ValueError("Empty body")
        except Exception as e:
            logger.error(f"❌ [Chat] Invalid JSON: {e}")
            return Response(
                f'data: {json.dumps({"type": "error", "error": "Invalid JSON"}, ensure_ascii=False)}\n\n',
                mimetype='text/event-stream'
            )
            
        user_id = data.get('user_id')
        message = data.get('message')
        
        if not user_id or not message:
            return Response(
                f'data: {json.dumps({"type": "error", "error": "Missing user_id or message"}, ensure_ascii=False)}\n\n',
                mimetype='text/event-stream'
            )
            
        logger.info(f"💬 [Chat] User: {user_id}, Message: {message[:50]}...")
        
        # Fetch Context (Profile, Plans, History)
        user_profile, exercise_plan, diet_plan, conversation_history = _fetch_chat_context(user_id)
        
        # Check for shortcut intents and fetch extra context
        extra_context = {}
        db = firestore.client()
        
        # Shortcuts keywords (English and Chinese)
        analyze_training_history_keywords = ["Analyze Training History", "分析训练历史"]
        analyze_diet_keywords = ["Analyze Diet Plan", "分析饮食计划"]
        analyze_training_plan_keywords = ["Analyze Training Plan", "分析训练计划"]
        
        should_fetch_weight = False
        should_fetch_trainings = False
        
        if any(k in message for k in analyze_training_history_keywords):
            should_fetch_weight = True
            should_fetch_trainings = True
            logger.info("🔍 Detected intent: Analyze Training History")
            
        elif any(k in message for k in analyze_diet_keywords):
            should_fetch_weight = True
            # Diet analysis might benefit from knowing recent training adherence
            should_fetch_trainings = True
            logger.info("🔍 Detected intent: Analyze Diet Plan")
            
        elif any(k in message for k in analyze_training_plan_keywords):
            should_fetch_weight = True
            # Training plan analysis might benefit from knowing recent adherence
            should_fetch_trainings = True 
            logger.info("🔍 Detected intent: Analyze Training Plan")
            
        if should_fetch_weight:
            extra_context['weight_history'] = _fetch_weight_history(db, user_id)
            
        if should_fetch_trainings:
            extra_context['recent_trainings'] = _fetch_recent_trainings(db, user_id)

        def generate():
            for event in stream_chat_with_ai(
                user_id=user_id,
                user_message=message,
                user_profile=user_profile,
                exercise_plan=exercise_plan,
                diet_plan=diet_plan,
                conversation_history=conversation_history,
                extra_context=extra_context
            ):
                yield f'data: {json.dumps(event, ensure_ascii=False)}\n\n'
                
        return Response(
            generate(),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'X-Accel-Buffering': 'no',
                'Connection': 'keep-alive'
            }
        )
        
    except Exception as e:
        logger.error(f"❌ [Chat] Handler error: {e}", exc_info=True)
        return Response(
            f'data: {json.dumps({"type": "error", "error": str(e)}, ensure_ascii=False)}\n\n',
            mimetype='text/event-stream'
        )

def _fetch_chat_context(user_id: str) -> Tuple[Dict[str, Any], Optional[Dict[str, Any]], Optional[Dict[str, Any]], list]:
    """
    Fetch all necessary context for chat.
    
    Returns:
        (user_profile, exercise_plan, diet_plan, conversation_history)
    """
    db = firestore.client()
    
    # 1. Fetch User Profile
    user_ref = db.collection('users').document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        # Should ideally error out, but fallback to empty for robustness
        logger.warning(f"⚠️ [Chat] User doc not found: {user_id}")
        user_profile = {'id': user_id, 'name': '学员'}
    else:
        user_profile = user_doc.to_dict()
        user_profile['id'] = user_id
        
    # 2. Fetch Active Plans
    exercise_plan_id = user_profile.get('activeExercisePlanId')
    diet_plan_id = user_profile.get('activeDietPlanId')
    
    exercise_plan = None
    if exercise_plan_id:
        try:
            ep_doc = db.collection('exercisePlans').document(exercise_plan_id).get()
            if ep_doc.exists:
                exercise_plan = ep_doc.to_dict()
        except Exception as e:
            logger.warning(f"⚠️ [Chat] Failed to fetch exercise plan {exercise_plan_id}: {e}")
            
    diet_plan = None
    if diet_plan_id:
        try:
            dp_doc = db.collection('dietPlans').document(diet_plan_id).get()
            if dp_doc.exists:
                diet_plan = dp_doc.to_dict()
        except Exception as e:
            logger.warning(f"⚠️ [Chat] Failed to fetch diet plan {diet_plan_id}: {e}")
            
    # 3. Fetch Conversation History (from MemoryManager)
    try:
        profile = MemoryManager.get_user_memory(user_id)
        # Assuming get_recent_conversations exists and returns list of dicts
        # Check streaming.py usage: profile.get_recent_conversations(limit=3)
        conversation_history = profile.get_recent_conversations(limit=10) # Get last 10 messages for context
    except Exception as e:
        logger.warning(f"⚠️ [Chat] Failed to fetch history: {e}")
        conversation_history = []
        
    return user_profile, exercise_plan, diet_plan, conversation_history

def _fetch_weight_history(db, user_id: str, days: int = 30) -> List[Dict[str, Any]]:
    """Fetch recent weight history."""
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        start_date_str = start_date.strftime("%Y-%m-%d")
        
        docs = db.collection('bodyMeasure') \
            .where('studentID', '==', user_id) \
            .where('recordDate', '>=', start_date_str) \
            .order_by('recordDate', direction=firestore.Query.DESCENDING) \
            .get()
            
        history = []
        for doc in docs:
            data = doc.to_dict()
            history.append({
                'date': data.get('recordDate'),
                'weight': data.get('weight'),
                'unit': data.get('weightUnit', 'kg')
            })
        return history
    except Exception as e:
        logger.warning(f"⚠️ Failed to fetch weight history: {e}")
        return []

def _fetch_recent_trainings(db, user_id: str, days: int = 30) -> List[Dict[str, Any]]:
    """Fetch recent training records."""
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        start_date_str = start_date.strftime("%Y-%m-%d")
        
        docs = db.collection('dailyTrainings') \
            .where('studentID', '==', user_id) \
            .where('date', '>=', start_date_str) \
            .order_by('date', direction=firestore.Query.DESCENDING) \
            .get()
            
        trainings = []
        for doc in docs:
            data = doc.to_dict()
            # Summarize training data to save context window
            exercises = data.get('exercises', [])
            completed_exercises = [e['name'] for e in exercises if e.get('completed')]
            
            trainings.append({
                'date': data.get('date'),
                'completed': data.get('completionStatus') == 'completed',
                'exercises_count': len(exercises),
                'completed_exercises_count': len(completed_exercises),
                'diet_adherence': 'Yes' if data.get('diet', {}).get('meals') else 'No' # Simple check
            })
        return trainings
    except Exception as e:
        logger.warning(f"⚠️ Failed to fetch training history: {e}")
        return []

