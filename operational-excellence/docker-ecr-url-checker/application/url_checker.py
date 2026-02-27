#!/usr/bin/env python3
"""
URL Checker - Containerized Version

This script checks the availability of URLs by making HTTP requests.
It's designed to run in a Docker container and demonstrates containerization
of a Python application.

Usage:
    python url_checker.py <url1> <url2> <url3> ...

Example:
    python url_checker.py https://aws.amazon.com https://google.com
"""

import sys
import requests
from tabulate import tabulate
from datetime import datetime


def check_url(url):
    """
    Check if a URL is reachable and return status information.
    
    Args:
        url (str): The URL to check
        
    Returns:
        dict: Dictionary containing URL status information
    """
    try:
        # Make HTTP GET request with timeout
        response = requests.get(url, timeout=5)
        
        return {
            'url': url,
            'status_code': response.status_code,
            'status': 'Available' if response.status_code == 200 else 'Warning',
            'response_time': f"{response.elapsed.total_seconds():.2f}s",
            'error': None
        }
    
    except requests.exceptions.Timeout:
        return {
            'url': url,
            'status_code': 'N/A',
            'status': 'Timeout',
            'response_time': 'N/A',
            'error': 'Request timed out after 5 seconds'
        }
    
    except requests.exceptions.ConnectionError:
        return {
            'url': url,
            'status_code': 'N/A',
            'status': 'Connection Error',
            'response_time': 'N/A',
            'error': 'Could not connect to server'
        }
    
    except requests.exceptions.RequestException as e:
        return {
            'url': url,
            'status_code': 'N/A',
            'status': 'Error',
            'response_time': 'N/A',
            'error': str(e)
        }


def main():
    """Main function to check multiple URLs and display results."""
    
    # Check if URLs were provided
    if len(sys.argv) < 2:
        print("Usage: python url_checker.py <url1> <url2> <url3> ...")
        print("\nExample:")
        print("  python url_checker.py https://aws.amazon.com https://google.com")
        sys.exit(1)
    
    # Get URLs from command line arguments
    urls = sys.argv[1:]
    
    print(f"\n{'='*70}")
    print(f"URL Checker - Containerized Version")
    print(f"Checking {len(urls)} URL(s) at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*70}\n")
    
    # Check each URL
    results = []
    for url in urls:
        print(f"Checking {url}...", end=' ')
        result = check_url(url)
        results.append(result)
        print(f"[{result['status']}]")
    
    # Prepare table data
    table_data = []
    for result in results:
        table_data.append([
            result['url'],
            result['status_code'],
            result['status'],
            result['response_time']
        ])
    
    # Display results in table format
    print(f"\n{'='*70}")
    print("Results Summary")
    print(f"{'='*70}\n")
    
    headers = ['URL', 'Status Code', 'Status', 'Response Time']
    print(tabulate(table_data, headers=headers, tablefmt='grid'))
    
    # Display errors if any
    errors = [r for r in results if r['error']]
    if errors:
        print(f"\n{'='*70}")
        print("Errors")
        print(f"{'='*70}\n")
        for error in errors:
            print(f"URL: {error['url']}")
            print(f"Error: {error['error']}\n")
    
    # Summary statistics
    available = len([r for r in results if r['status'] == 'Available'])
    unavailable = len(results) - available
    
    print(f"{'='*70}")
    print(f"Summary: {available} available, {unavailable} unavailable")
    print(f"{'='*70}\n")
    
    # Exit with appropriate code
    sys.exit(0 if unavailable == 0 else 1)


if __name__ == '__main__':
    main()
