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

def set_branch_protection(repo_name, branch_name):
    """
    Set branch protection rules for the specified branch.

    :param repo_name: Name of the repository.
    :param branch_name: Name of the branch to protect.
    """
    url = f'https://api.github.com/repos/{GITHUB_ORG}/{repo_name}/branches/{branch_name}/protection'
    data = {
        'required_status_checks': None,  # Change this if you want to require specific status checks
        'enforce_admins': True,
        'required_pull_request_reviews': {
            'dismiss_stale_reviews': False,
            'dismissal_restrictions': {},  # Set this to an empty object
            'require_code_owner_reviews': False,
            'required_approving_review_count': 1
        },
        'restrictions': None,  # Set this to restrict who can push to the branch
        'allow_force_pushes': False,
        'allow_deletions': False,
    }

    response = requests.put(url, json=data, auth=(GITHUB_TOKEN, ''))

    if response.status_code == 200:
        print(f'Branch protection rules set for {repo_name}/{branch_name}.')
    else:
        print(f'Failed to set branch protection for {repo_name}/{branch_name}: {response.json()}')

def main():
    branch_name = input('Enter the branch name to protect: ')
    for repo in repos:
        # Set branch protection for the specified branch only
        set_branch_protection(repo, branch_name)

if __name__ == '__main__':
    main()
