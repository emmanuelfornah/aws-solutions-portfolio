#!/usr/bin/env python3
"""
URL Checker Application
Checks the availability of URLs by performing HTTP GET requests
and displays results in a formatted table.
"""

import sys
import requests
from tabulate import tabulate


def check_url(url):
    """
    Check if a URL is reachable by performing an HTTP GET request.
    
    Args:
        url (str): The URL to check
        
    Returns:
        tuple: (url, status, status_code) where status is 'Success' or 'Failed'
    """
    try:
        response = requests.get(url, timeout=5)
        
        # Consider 2xx status codes as success
        if 200 <= response.status_code < 300:
            return (url, "Success", response.status_code)
        else:
            return (url, "Failed", response.status_code)
            
    except requests.exceptions.ConnectionError:
        return (url, "Failed", "Connection Error")
    except requests.exceptions.Timeout:
        return (url, "Failed", "Timeout")
    except requests.exceptions.RequestException as e:
        return (url, "Failed", f"Error: {type(e).__name__}")


def main():
    """
    Main function to process command-line arguments and check URLs.
    """
    # Check if URLs were provided
    if len(sys.argv) < 2:
        print("Usage: python3 url_checker.py <url1> <url2> ... <urlN>")
        print("\nExample:")
        print("  python3 url_checker.py https://aws.amazon.com https://github.com")
        sys.exit(1)
    
    # Get URLs from command-line arguments
    urls = sys.argv[1:]
    
    print(f"\nChecking {len(urls)} URL(s)...\n")
    
    # Check each URL and collect results
    results = []
    for url in urls:
        result = check_url(url)
        results.append(result)
    
    # Display results in a formatted table
    headers = ["URL", "Status", "Status Code"]
    print("URL Checker Results")
    print(tabulate(results, headers=headers, tablefmt="fancy_grid"))
    print()
    
    # Summary statistics
    successful = sum(1 for r in results if r[1] == "Success")
    failed = len(results) - successful
    
    print(f"Summary: {successful} successful, {failed} failed out of {len(results)} total")


if __name__ == "__main__":
    main()
