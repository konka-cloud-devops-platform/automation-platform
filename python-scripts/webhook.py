import requests
import getpass
import json

# Configuration
GITHUB_ORG = 'srk-ullagallu'
GITHUB_TOKEN = getpass.getpass('Enter your GitHub Personal Access Token: ')

repos = [
    'catalogue',
    'user',
    'cart',
    'shipping',
    'payment',
    'frontend'
]

# Webhook configuration
WEBHOOK_URL = 'http://ws.bapatlas.site:8080/github-webhook/'
WEBHOOK_EVENTS = ['push', 'pull_request']

def add_webhook(repo_name):
    """
    Add a webhook to the specified repository.
    
    :param repo_name: Name of the repository.
    """
    url = f'https://api.github.com/repos/{GITHUB_ORG}/{repo_name}/hooks'
    webhook_data = {
        'config': {
            'url': WEBHOOK_URL,
            'content_type': 'json',
            'insecure_ssl': '0'  # Set to '1' to allow insecure SSL (not recommended)
        },
        'events': WEBHOOK_EVENTS,
        'active': True
    }

    response = requests.post(url, json=webhook_data, auth=(GITHUB_TOKEN, ''))

    if response.status_code == 201:
        print(f'Successfully added webhook to {repo_name}.')
    else:
        print(f'Failed to add webhook to {repo_name}: {response.json()}')

def main():
    for repo in repos:
        add_webhook(repo)

if __name__ == '__main__':
    main()
