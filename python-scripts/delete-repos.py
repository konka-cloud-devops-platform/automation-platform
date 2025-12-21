import requests
import getpass

# Configuration
GITHUB_ORG = 'srk-ullagallu'
GITHUB_TOKEN = getpass.getpass('Enter your GitHub Personal Access Token: ')

def delete_github_org_repo(repo_name):
    """
    Deletes a repository from a GitHub organization.
    
    :param repo_name: Name of the repository to delete (e.g., 'repo-name').
    """
    url = f'https://api.github.com/repos/{GITHUB_ORG}/{repo_name}'
    headers = {
        'Authorization': f'token {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github.v3+json'
    }
    
    response = requests.delete(url, headers=headers)
    
    if response.status_code == 204:
        print(f'Successfully deleted repository: {GITHUB_ORG}/{repo_name}')
    else:
        print(f'Failed to delete repository: {GITHUB_ORG}/{repo_name}')
        print(f'Status code: {response.status_code}')
        try:
            print(f'Message: {response.json()}')
        except ValueError:
            print("No JSON message in response")

# List of repositories to delete
repos_to_delete = [
    'catalogue',
    'user',
    'cart',
    'shipping',
    'payment',
    'frontend'
]

# Loop through each repository and delete it
for repo in repos_to_delete:
    delete_github_org_repo(repo)
