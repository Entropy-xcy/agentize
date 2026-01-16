# Tutorial 04: Configuring Project Board Automation

**Read time: 3-5 minutes**

After running `/setup-viewboard`, you need to configure a Personal Access Token (PAT) to enable automatic issue-to-project synchronization.

## Why This Is Needed

The `/setup-viewboard` command creates a GitHub Actions workflow (`.github/workflows/add-to-project.yml`) that automatically adds new issues to your project board. This workflow requires a PAT with project permissions to function.

## Step 1: Open GitHub Settings

Click your profile picture in the top-right corner, then select **Settings**.

![Open Settings](images/open-settings.png)

## Step 2: Navigate to Developer Settings

Scroll down to the bottom of the left sidebar and click **Developer settings**.

![Developer Settings](images/developer-settings.png)

## Step 3: Create a Personal Access Token

In the Developer settings, expand **Personal access tokens** and click **Tokens (classic)**.

![Create PAT](images/create-pat.png)

## Step 4: Generate a Classic Token

Click **Generate new token** and select **Generate new token (classic)**.

![Classic Token](images/classic-token.png)

## Step 5: Configure the Token

Give your token a descriptive name (e.g., `agentize-project-automation`).

![Give a Name to PAT](images/give-a-name-to-pat.png)

## Step 6: Grant Project Permissions

Scroll down and check the **project** scope under permissions. This allows the workflow to add issues to your project board.

![Give Project Permission](images/give-proj-permission.png)

Click **Generate token** at the bottom and **copy the token value immediately** - you won't be able to see it again.

## Step 7: Go to Repository Settings

Navigate to your repository and click **Settings** in the repository navigation bar.

![Go to Repo Settings](images/go-to-repo-settings.png)

## Step 8: Create the Repository Secret

In the repository settings sidebar:
1. Expand **Secrets and variables**
2. Click **Actions**
3. Click **New repository secret**
4. Name: `ADD_TO_PROJECT_PAT`
5. Value: Paste the token you copied earlier
6. Click **Add secret**

![Secrets for Variable](images/secrets-for-variable.png)

## Verification

Once configured, any new issue created in your repository will automatically be added to your project board. You can verify this by:

1. Creating a test issue
2. Checking the **Actions** tab for the workflow run
3. Confirming the issue appears in your project board

## Troubleshooting

**Workflow fails with "Resource not accessible by integration"**
- Ensure the PAT has the `project` scope
- Verify the secret name is exactly `ADD_TO_PROJECT_PAT`

**Issues not appearing on board**
- Check that the project ID in `.agentize.yaml` matches your actual project
- Verify the workflow file exists at `.github/workflows/add-to-project.yml`

## Next Steps

With project automation configured, your issues will automatically flow into the project board where you can track their status through the agentize workflow stages: Proposed → Refining → Plan Accepted → In Progress → Done.
