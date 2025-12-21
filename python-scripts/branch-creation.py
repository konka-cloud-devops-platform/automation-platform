import requests
import getpass

# Configuration
GITHUB_ORG = 'srk-ullagallu'
GITHUB_TOKEN = getpass.getpass('Enter your GitHub Personal Access Token: ')

# List of repositories
repos = [
    'catalogue',
    'user',
    'cart',
    'shipping',
    'payment',
    'frontend'
]

def create_branch(repo_name, branch_name, base_branch='main'):
    """
    Create a new branch from the specified base branch.

    :param repo_name: Name of the repository.
    :param branch_name: Name of the new branch to create.
    :param base_branch: Name of the base branch from which to create the new branch.
    """
    # Get the SHA of the base branch
    url = f'https://api.github.com/repos/{GITHUB_ORG}/{repo_name}/git/refs/heads/{base_branch}'
    response = requests.get(url, auth=(GITHUB_TOKEN, ''))

    if response.status_code != 200:
        print(f'Failed to get {base_branch} branch SHA for {repo_name}: {response.json()}')
        return

    base_branch_sha = response.json()['object']['sha']

    # Create the new branch
    create_url = f'https://api.github.com/repos/{GITHUB_ORG}/{repo_name}/git/refs'
    branch_data = {
        'ref': f'refs/heads/{branch_name}',
        'sha': base_branch_sha
    }

    response = requests.post(create_url, json=branch_data, auth=(GITHUB_TOKEN, ''))

    if response.status_code == 201:
        print(f'Successfully created branch {branch_name} in {repo_name}.')
    else:
        print(f'Failed to create branch {branch_name} in {repo_name}: {response.json()}')

def main():
    branch_name = input('Enter the new branch name to create: ')
    for repo in repos:
        create_branch(repo, branch_name)

if __name__ == '__main__':
    main()
