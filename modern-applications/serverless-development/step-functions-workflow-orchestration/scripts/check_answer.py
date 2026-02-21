"""
Check Answer Lambda Function
Validates player's answer and updates score
"""

import json
import boto3
import os
from datetime import datetime

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
GAMES_TABLE = os.environ.get('GAMES_TABLE', 'TriviaGames')
ANSWERS_TABLE = os.environ.get('ANSWERS_TABLE', 'PlayerAnswers')

# DynamoDB tables
games_table = dynamodb.Table(GAMES_TABLE)
answers_table = dynamodb.Table(ANSWERS_TABLE)

def lambda_handler(event, context):
    """
    Check if player's answer is correct and update score
    
    Args:
        event: Step Functions state with game state and current question
        context: Lambda context object
        
    Returns:
        Answer result with correctness and updated score
    """
    
    try:
        # Extract game state and question
        game_state = event.get('gameState', {})
        current_question = event.get('currentQuestion', {})
        
        game_id = game_state.get('gameId')
        question_id = current_question.get('questionId')
        correct_answer = current_question.get('correctAnswer')
        
        print(f"Checking answer for game: {game_id}, question: {question_id}")
        
        # Retrieve player's answer from DynamoDB
        # In real implementation, player submits answer via API
        # For demo, we'll simulate or retrieve from answers table
        try:
            response = answers_table.get_item(
                Key={
                    'gameId': game_id,
                    'questionId': question_id
                }
            )
            player_answer = response.get('Item', {}).get('answer', '')
            answer_time = response.get('Item', {}).get('timestamp', datetime.utcnow().isoformat())
        except:
            # No answer submitted (timeout)
            player_answer = ''
            answer_time = datetime.utcnow().isoformat()
        
        # Check if answer is correct
        is_correct = player_answer.lower() == correct_answer.lower()
        
        # Calculate points (could be time-based)
        points = 10 if is_correct else 0
        
        # Create answer result
        answer_result = {
            'questionId': question_id,
            'playerAnswer': player_answer,
            'correctAnswer': correct_answer,
            'isCorrect': is_correct,
            'points': points,
            'answerTime': answer_time
        }
        
        print(f"Answer result: {'Correct' if is_correct else 'Incorrect'}, Points: {points}")
        
        return answer_result
        
    except Exception as e:
        print(f"Error checking answer: {str(e)}")
        raise
