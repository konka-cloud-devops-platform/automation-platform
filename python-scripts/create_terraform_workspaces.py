import requests
from getpass import getpass

ORG_NAME = "ECS-SPA"
BASE_URL = "https://app.terraform.io/api/v2"

def get_headers(api_token):
    return {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/vnd.api+json"
    }

def create_workspace(api_token, workspace_name):
    url = f"{BASE_URL}/organizations/{ORG_NAME}/workspaces"
    headers = get_headers(api_token)
    payload = {
        "data": {
            "type": "workspaces",
            "attributes": {
                "name": workspace_name,
                "execution-mode": "remote"
            }
        }
    }
    response = requests.post(url, json=payload, headers=headers)
    if response.status_code == 201:
        print(f"Workspace '{workspace_name}' created successfully!")
    else:
        print(f"Failed to create workspace '{workspace_name}': {response.text}")

def main():
    print("Enter your Terraform Cloud API token:")
    api_token = getpass("Token: ")
    
    workspaces = ["vpc", "security-group", "alb-tg"]
    for ws in workspaces:
        create_workspace(api_token, ws)

if __name__ == "__main__":
    main()
