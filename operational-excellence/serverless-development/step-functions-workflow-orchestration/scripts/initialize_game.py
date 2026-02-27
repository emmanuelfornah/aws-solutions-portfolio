"""
Initialize Game Lambda Function
Sets up a new trivia game session
"""

import json
import boto3
import os
import uuid
from datetime import datetime

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
GAMES_TABLE = os.environ.get('GAMES_TABLE', 'TriviaGames')

# DynamoDB table
games_table = dynamodb.Table(GAMES_TABLE)

def lambda_handler(event, context):
    """
    Initialize a new trivia game session
    
    Args:
        event: Step Functions input with player information
        context: Lambda context object
        
    Returns:
        Game state object
    """
    
    try:
        # Extract player info from event
        player_id = event.get('playerId', str(uuid.uuid4()))
        player_name = event.get('playerName', 'Anonymous')
        difficulty = event.get('difficulty', 'medium')
        
        # Generate game ID
        game_id = str(uuid.uuid4())
        
        # Create initial game state
        game_state = {
            'gameId': game_id,
            'playerId': player_id,
            'playerName': player_name,
            'difficulty': difficulty,
            'questionNumber': 0,
            'score': 0,
            'correctAnswers': 0,
            'incorrectAnswers': 0,
            'startTime': datetime.utcnow().isoformat(),
            'status': 'IN_PROGRESS',
            'questions': []
        }
        
        print(f"Initializing game: {game_id} for player: {player_name}")
        
        # Save initial game state to DynamoDB
        games_table.put_item(Item=game_state)
        
        print(f"Game initialized successfully: {game_id}")
        
        return game_state
        
    except Exception as e:
        print(f"Error initializing game: {str(e)}")
        raise
