"""
Presidents Application - Main Logic
This Flask application displays information about US Presidents stored in DynamoDB.
"""

import boto3
from flask import Flask, render_template, jsonify
from datetime import datetime
from dateutil.relativedelta import relativedelta
from botocore.exceptions import ClientError

app = Flask(__name__)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('Presidents')


def calculate_age(born_date, died_date):
    """
    Calculate age in years between two dates using relativedelta.
    
    This function correctly calculates age by accounting for the actual
    dates, not just the year difference.
    
    Args:
        born_date (datetime): Birth date
        died_date (datetime): Death date
    
    Returns:
        int: Age in complete years
    
    Example:
        >>> born = datetime(1735, 10, 30)
        >>> died = datetime(1826, 7, 4)
        >>> calculate_age(born, died)
        90
    """
    if not isinstance(born_date, datetime) or not isinstance(died_date, datetime):
        raise ValueError("Both dates must be datetime objects")
    
    if died_date < born_date:
        raise ValueError("Death date cannot be before birth date")
    
    # Use relativedelta for accurate age calculation
    # This accounts for the actual dates, not just year subtraction
    age = relativedelta(died_date, born_date).years
    
    return age


def get_all_presidents():
    """
    Retrieve all presidents from DynamoDB table.
    
    Returns:
        list: List of president dictionaries with calculated ages
    """
    try:
        response = table.scan()
        presidents = response.get('Items', [])
        
        # Calculate age for each president
        for president in presidents:
            if 'Born' in president and 'Died' in president:
                # Convert string dates to datetime objects
                born = datetime.strptime(president['Born'], '%Y-%m-%d')
                died = datetime.strptime(president['Died'], '%Y-%m-%d')
                
                # Calculate age using relativedelta (correct method)
                president['Age'] = calculate_age(born, died)
                
                # Store datetime objects for template use
                president['BornDate'] = born
                president['DiedDate'] = died
        
        return presidents
    
    except ClientError as e:
        print(f"Error retrieving presidents: {e}")
        return []


def get_president_by_name(name):
    """
    Retrieve a specific president by name.
    
    Args:
        name (str): President's full name
    
    Returns:
        dict: President information with calculated age, or None if not found
    """
    try:
        response = table.get_item(Key={'Name': name})
        president = response.get('Item')
        
        if president and 'Born' in president and 'Died' in president:
            born = datetime.strptime(president['Born'], '%Y-%m-%d')
            died = datetime.strptime(president['Died'], '%Y-%m-%d')
            
            president['Age'] = calculate_age(born, died)
            president['BornDate'] = born
            president['DiedDate'] = died
        
        return president
    
    except ClientError as e:
        print(f"Error retrieving president {name}: {e}")
        return None


@app.route('/')
def index():
    """
    Main page displaying all presidents.
    """
    presidents = get_all_presidents()
    return render_template('index.html', presidents=presidents)


@app.route('/api/presidents')
def api_presidents():
    """
    API endpoint returning all presidents as JSON.
    """
    presidents = get_all_presidents()
    
    # Convert datetime objects to strings for JSON serialization
    for president in presidents:
        if 'BornDate' in president:
            president['BornDate'] = president['BornDate'].strftime('%Y-%m-%d')
        if 'DiedDate' in president:
            president['DiedDate'] = president['DiedDate'].strftime('%Y-%m-%d')
    
    return jsonify(presidents)


@app.route('/api/president/<name>')
def api_president(name):
    """
    API endpoint returning a specific president as JSON.
    """
    president = get_president_by_name(name)
    
    if president:
        # Convert datetime objects to strings for JSON serialization
        if 'BornDate' in president:
            president['BornDate'] = president['BornDate'].strftime('%Y-%m-%d')
        if 'DiedDate' in president:
            president['DiedDate'] = president['DiedDate'].strftime('%Y-%m-%d')
        
        return jsonify(president)
    else:
        return jsonify({'error': 'President not found'}), 404


@app.route('/health')
def health():
    """
    Health check endpoint for load balancers and monitoring.
    """
    return jsonify({'status': 'healthy', 'service': 'presidents-app'}), 200


if __name__ == '__main__':
    # Run the Flask development server
    # In production, use gunicorn or similar WSGI server
    app.run(host='0.0.0.0', port=5000, debug=False)
