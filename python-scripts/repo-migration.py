import os
import subprocess
import requests
import getpass

# Configuration
SOURCE_ORG = 'instana-srk'
TARGET_ORG = 'srk-ullagallu'
GITHUB_TOKEN = getpass.getpass('Enter your GitHub Personal Access Token: ')

def create_target_repo(repo_name):
    """
    Creates a repository in the target GitHub organization.
    
    :param repo_name: Name of the repository to create (e.g., 'repo-name').
    """
    url = f'https://api.github.com/orgs/{TARGET_ORG}/repos'
    headers = {
        'Authorization': f'token {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github.v3+json'
    }
    data = {
        'name': repo_name,
        'private': False  # Set to True if you want to create private repositories
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 201:
        print(f'Successfully created repository: {TARGET_ORG}/{repo_name}')
        return True
    else:
        print(f'Failed to create repository: {TARGET_ORG}/{repo_name}')
        print(f'Status code: {response.status_code}')
        try:
            print(f'Message: {response.json()}')
        except ValueError:
            print("No JSON message in response")
        return False

def migrate_repo(repo_name):
    """
    Migrates a repository from the source organization to the target organization.
    
    :param repo_name: Name of the repository to migrate.
    """
    # URLs for cloning and pushing
    source_url = f'https://github.com/{SOURCE_ORG}/{repo_name}.git'
    target_url = f'https://{GITHUB_TOKEN}@github.com/{TARGET_ORG}/{repo_name}.git'
    
    # Clone the source repository
    clone_command = f'git clone --mirror {source_url}'
    push_command = f'cd {repo_name}.git && git remote set-url origin {target_url} && git push --mirror'
    
    try:
        # Run the clone command
        subprocess.run(clone_command, shell=True, check=True)
        print(f'Successfully cloned {repo_name} from {SOURCE_ORG}')
        
        # Run the push command
        subprocess.run(push_command, shell=True, check=True)
        print(f'Successfully migrated {repo_name} to {TARGET_ORG}')
        
        # Clean up the local clone
        subprocess.run(f'rm -rf {repo_name}.git', shell=True)
    except subprocess.CalledProcessError as e:
        print(f'Error migrating {repo_name}: {e}')

# List of repositories to migrate
repos_to_migrate = [
    'ibm-instana'
]

# Loop through each repository and migrate it
for repo in repos_to_migrate:
    if create_target_repo(repo):
        migrate_repo(repo)
