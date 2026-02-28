"""
Unit Tests for Presidents Application
Tests the age calculation logic and application functions.
"""

import pytest
from datetime import datetime
from unittest.mock import Mock, patch, MagicMock
from botocore.exceptions import ClientError

# Import the application module
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../app')))

from presidents import calculate_age, get_all_presidents, get_president_by_name


class TestAgeCalculation:
    """Test suite for age calculation function."""
    
    def test_calculate_age_john_adams(self):
        """
        Test age calculation for President John Adams.
        
        John Adams:
        - Born: October 30, 1735
        - Died: July 4, 1826
        - Age: 90 years (died before his 91st birthday)
        """
        born = datetime(1735, 10, 30)
        died = datetime(1826, 7, 4)
        
        age = calculate_age(born, died)
        
        # John Adams was 90 years old when he died
        assert age == 90, f"Expected 90, got {age}"
    
    def test_calculate_age_george_washington(self):
        """
        Test age calculation for President George Washington.
        
        George Washington:
        - Born: February 22, 1732
        - Died: December 14, 1799
        - Age: 67 years
        """
        born = datetime(1732, 2, 22)
        died = datetime(1799, 12, 14)
        
        age = calculate_age(born, died)
        
        assert age == 67, f"Expected 67, got {age}"
    
    def test_calculate_age_thomas_jefferson(self):
        """
        Test age calculation for President Thomas Jefferson.
        
        Thomas Jefferson:
        - Born: April 13, 1743
        - Died: July 4, 1826
        - Age: 83 years
        """
        born = datetime(1743, 4, 13)
        died = datetime(1826, 7, 4)
        
        age = calculate_age(born, died)
        
        assert age == 83, f"Expected 83, got {age}"
    
    def test_calculate_age_james_madison(self):
        """
        Test age calculation for President James Madison.
        
        James Madison:
        - Born: March 16, 1751
        - Died: June 28, 1836
        - Age: 85 years
        """
        born = datetime(1751, 3, 16)
        died = datetime(1836, 6, 28)
        
        age = calculate_age(born, died)
        
        assert age == 85, f"Expected 85, got {age}"
    
    def test_calculate_age_same_year_before_birthday(self):
        """
        Test age calculation when death occurs in same year before birthday.
        Should return 0 years.
        """
        born = datetime(2000, 6, 15)
        died = datetime(2000, 3, 10)  # Died before birthday
        
        age = calculate_age(born, died)
        
        assert age == 0, f"Expected 0, got {age}"
    
    def test_calculate_age_exactly_one_year(self):
        """
        Test age calculation for exactly one year.
        """
        born = datetime(2000, 1, 1)
        died = datetime(2001, 1, 1)
        
        age = calculate_age(born, died)
        
        assert age == 1, f"Expected 1, got {age}"
    
    def test_calculate_age_leap_year(self):
        """
        Test age calculation across leap years.
        """
        born = datetime(2000, 2, 29)  # Leap year birthday
        died = datetime(2020, 3, 1)
        
        age = calculate_age(born, died)
        
        assert age == 20, f"Expected 20, got {age}"
    
    def test_calculate_age_invalid_dates(self):
        """
        Test that invalid date types raise ValueError.
        """
        with pytest.raises(ValueError, match="Both dates must be datetime objects"):
            calculate_age("2000-01-01", "2020-01-01")
    
    def test_calculate_age_death_before_birth(self):
        """
        Test that death date before birth date raises ValueError.
        """
        born = datetime(2000, 1, 1)
        died = datetime(1999, 1, 1)
        
        with pytest.raises(ValueError, match="Death date cannot be before birth date"):
            calculate_age(born, died)


class TestGetAllPresidents:
    """Test suite for get_all_presidents function."""
    
    @patch('presidents.table')
    def test_get_all_presidents_success(self, mock_table):
        """
        Test successful retrieval of all presidents from DynamoDB.
        """
        # Mock DynamoDB response
        mock_table.scan.return_value = {
            'Items': [
                {
                    'Name': 'John Adams',
                    'Born': '1735-10-30',
                    'Died': '1826-07-04',
                    'Party': 'Federalist'
                },
                {
                    'Name': 'George Washington',
                    'Born': '1732-02-22',
                    'Died': '1799-12-14',
                    'Party': 'None'
                }
            ]
        }
        
        presidents = get_all_presidents()
        
        assert len(presidents) == 2
        assert presidents[0]['Name'] == 'John Adams'
        assert presidents[0]['Age'] == 90
        assert presidents[1]['Name'] == 'George Washington'
        assert presidents[1]['Age'] == 67
    
    @patch('presidents.table')
    def test_get_all_presidents_empty(self, mock_table):
        """
        Test retrieval when no presidents exist in table.
        """
        mock_table.scan.return_value = {'Items': []}
        
        presidents = get_all_presidents()
        
        assert len(presidents) == 0
    
    @patch('presidents.table')
    def test_get_all_presidents_error(self, mock_table):
        """
        Test error handling when DynamoDB scan fails.
        """
        mock_table.scan.side_effect = ClientError(
            {'Error': {'Code': 'ResourceNotFoundException', 'Message': 'Table not found'}},
            'Scan'
        )
        
        presidents = get_all_presidents()
        
        assert len(presidents) == 0


class TestGetPresidentByName:
    """Test suite for get_president_by_name function."""
    
    @patch('presidents.table')
    def test_get_president_by_name_success(self, mock_table):
        """
        Test successful retrieval of a specific president.
        """
        mock_table.get_item.return_value = {
            'Item': {
                'Name': 'John Adams',
                'Born': '1735-10-30',
                'Died': '1826-07-04',
                'Party': 'Federalist'
            }
        }
        
        president = get_president_by_name('John Adams')
        
        assert president is not None
        assert president['Name'] == 'John Adams'
        assert president['Age'] == 90
    
    @patch('presidents.table')
    def test_get_president_by_name_not_found(self, mock_table):
        """
        Test retrieval when president doesn't exist.
        """
        mock_table.get_item.return_value = {}
        
        president = get_president_by_name('Unknown President')
        
        assert president is None
    
    @patch('presidents.table')
    def test_get_president_by_name_error(self, mock_table):
        """
        Test error handling when DynamoDB get_item fails.
        """
        mock_table.get_item.side_effect = ClientError(
            {'Error': {'Code': 'ResourceNotFoundException', 'Message': 'Table not found'}},
            'GetItem'
        )
        
        president = get_president_by_name('John Adams')
        
        assert president is None


class TestFlaskRoutes:
    """Test suite for Flask application routes."""
    
    @pytest.fixture
    def client(self):
        """Create a test client for the Flask application."""
        from presidents import app
        app.config['TESTING'] = True
        with app.test_client() as client:
            yield client
    
    @patch('presidents.get_all_presidents')
    def test_api_presidents_endpoint(self, mock_get_all, client):
        """
        Test the /api/presidents endpoint.
        """
        mock_get_all.return_value = [
            {
                'Name': 'John Adams',
                'Age': 90,
                'BornDate': datetime(1735, 10, 30),
                'DiedDate': datetime(1826, 7, 4)
            }
        ]
        
        response = client.get('/api/presidents')
        
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 1
        assert data[0]['Name'] == 'John Adams'
        assert data[0]['Age'] == 90
    
    @patch('presidents.get_president_by_name')
    def test_api_president_endpoint_found(self, mock_get_president, client):
        """
        Test the /api/president/<name> endpoint when president exists.
        """
        mock_get_president.return_value = {
            'Name': 'John Adams',
            'Age': 90,
            'BornDate': datetime(1735, 10, 30),
            'DiedDate': datetime(1826, 7, 4)
        }
        
        response = client.get('/api/president/John%20Adams')
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['Name'] == 'John Adams'
        assert data['Age'] == 90
    
    @patch('presidents.get_president_by_name')
    def test_api_president_endpoint_not_found(self, mock_get_president, client):
        """
        Test the /api/president/<name> endpoint when president doesn't exist.
        """
        mock_get_president.return_value = None
        
        response = client.get('/api/president/Unknown')
        
        assert response.status_code == 404
        data = response.get_json()
        assert 'error' in data
    
    def test_health_endpoint(self, client):
        """
        Test the /health endpoint.
        """
        response = client.get('/health')
        
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'healthy'
        assert data['service'] == 'presidents-app'


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
