import requests
import getpass

# Configuration
GITHUB_ORG = 'srk-ullagallu'
GITHUB_TOKEN = getpass.getpass('Enter your GitHub Personal Access Token: ')

def create_github_org_repo(repo_name):
    """
    Creates a repository in a GitHub organization.

    :param repo_name: Name of the repository to create (e.g., 'repo-name').
    """
    url = f'https://api.github.com/orgs/{GITHUB_ORG}/repos'
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
        print(f'Successfully created repository: {GITHUB_ORG}/{repo_name}')
    else:
        print(f'Failed to create repository: {GITHUB_ORG}/{repo_name}')
        print(f'Status code: {response.status_code}')
        try:
            print(f'Message: {response.json()}')
        except ValueError:
            print("No JSON message in response")


def main():
    print("Choose how you want to provide repository names:")
    print("1. Enter manually")
    print("2. Use a predefined list")
    choice = input("Enter your choice (1 or 2): ").strip()

    if choice == '1':
        repos_to_create = input(
            "Enter repository names separated by commas (e.g., repo1,repo2): "
        ).split(',')
        repos_to_create = [repo.strip() for repo in repos_to_create if repo.strip()]
    elif choice == '2':
        repos_to_create = ['catalogue', 'user', 'cart', 'shipping', 'payment', 'frontend']
        print(f"Using predefined list: {', '.join(repos_to_create)}")
    else:
        print("Invalid choice. Exiting.")
        return

    # Loop through each repository name and create it
    for repo in repos_to_create:
        create_github_org_repo(repo)


if __name__ == "__main__":
    main()
