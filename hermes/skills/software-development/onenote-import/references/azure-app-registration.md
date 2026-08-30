# Microsoft Entra App Registration for OneNote Graph Access

This guide walks through creating a Microsoft Entra (formerly Azure Active Directory)
app registration so the `onenote-import` skill can read your OneNote notebooks via
Microsoft Graph.

## What you will get

- **Application (client) ID** — set as `ONENOTE_CLIENT_ID`.
- **Directory (tenant) ID** — set as `ONENOTE_TENANT_ID`.

## Steps

### 1. Open the Azure portal

Navigate to https://portal.azure.com and sign in with the Microsoft account that
owns your OneNote notebooks.

### 2. Go to App registrations

- Click the hamburger menu (☰) in the top-left.
- Select **Microsoft Entra ID**.
- In the left pane, select **App registrations**.
- Click **+ New registration** at the top.

### 3. Configure the app

Fill in the registration form:

| Field | Value |
|-------|-------|
| **Name** | `Hermes OneNote Import` (or any descriptive name) |
| **Supported account types** | Select "Accounts in any organizational directory and personal Microsoft accounts" |
| **Redirect URI** | Leave blank for device-code flow |

Click **Register**.

### 4. Copy the IDs

On the app's **Overview** page:

- Copy **Application (client) ID**.
- Copy **Directory (tenant) ID**.

Save them for the next step. These become your `ONENOTE_CLIENT_ID` and
`ONENOTE_TENANT_ID`.

### 5. Add API permissions

In the left pane:

1. Select **API permissions**.
2. Click **+ Add a permission**.
3. Choose **Microsoft Graph**.
4. Choose **Delegated permissions**.
5. Search for and check:
   - `User.Read`
   - `Notes.Read`
6. Click **Add permissions**.

You should see both permissions listed under **Configured permissions**.

### 6. Grant admin consent (work/school accounts only)

If you are using a **personal Microsoft account** (Outlook.com, Live, Hotmail),
you can skip this step.

If you are using a **work or school account**:

- Click **Grant admin consent for <tenant>**.
- Sign in with an administrator account if prompted.
- Confirm. The **Status** column should show a green checkmark for each permission.

Without admin consent, device-code sign-in will fail with an authorization error.

### 7. Set environment variables in your shell

In the terminal where you run the skill:

```bash
export ONENOTE_CLIENT_ID="your-client-id-here"
export ONENOTE_TENANT_ID="your-tenant-id-here"
```

To make these persistent, add them to `~/.bashrc`, `~/.zshrc`, or your NixOS
home-manager environment variables.

### 8. Run the skill

```bash
cd /mnt/wsl/projects/git/dotfiles
python3 hermes/skills/software-development/onenote-import/scripts/onenote_import.py \
  --notebook "Nix OS" \
  --section "zsh" \
  --output onenote/notes
```

The script will print a URL (`https://microsoft.com/devicelogin`) and a code.
Open the URL in a browser, enter the code, and sign in with the same Microsoft
account.

## Troubleshooting

### "AADSTS700016: Application was not found"

The `ONENOTE_CLIENT_ID` is wrong or the app registration is in a different
tenant. Recheck the **Application (client) ID** on the Overview page.

### "AADSTS65001: The user or administrator has not consented"

For work/school accounts, an admin must grant consent (step 6). Personal
accounts do not need admin consent.

### "Insufficient privileges to complete the operation"

Make sure `Notes.Read` is added and, for work/school accounts, that admin
consent has been granted.

### Token expires / repeated sign-in prompts

The current script does not cache tokens. A future version may store a refresh
token in a keyring-backed location.

## Notes

- The app does **not** need a client secret for device-code flow.
- The app does **not** need a redirect URI for device-code flow.
- Only delegated permissions are used; the app cannot access notebooks you do
  not have permission to read.
