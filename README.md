# User Account Manager

A PowerShell IT Help Desk tool for managing local user accounts, simulating the day-to-day Active Directory tasks performed by IT support staff.

## Features

- **Create** new user accounts with full name, department, and password
- **Disable** accounts for offboarding or security incidents
- **Enable / Unlock** accounts locked out after failed login attempts
- **Reset passwords** for users who are locked out
- **View detailed account info** â group memberships, last logon, password age
- **List all users** in a formatted table
- **Bulk create users** from a CSV file (ideal for onboarding batches)
- **Export audit reports** to CSV for compliance and review
- All actions are **logged** with timestamp to `UserAccountManager.log`

## Technologies

- PowerShell 5.1+
- Windows Local User Management (`Microsoft.PowerShell.LocalAccounts` module)
- Designed to mirror Active Directory workflows (`Get-ADUser`, `New-ADUser`, etc.)

## Getting Started

```powershell
# Run as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\UserAccountManager.ps1
```

## Bulk User CSV Format

Use `users_template.csv` as your starting point:

```
FirstName, LastName, Username, Password, Department, Email
John, Doe, jdoe, TempPass123!, IT Support, jdoe@company.com
```

## Project Structure

```
user-account-manager/
âââ UserAccountManager.ps1   # Main script
âââ users_template.csv       # Template for bulk user creation
âââ UserAccountManager.log   # Auto-generated activity log
âââ account_audit.csv        # Auto-generated audit export
âââ README.md
```

## Skills Demonstrated

- Active Directory / local user account management
- PowerShell scripting and automation
- IT security practices (account lockout, offboarding)
- Bulk provisioning and CSV data handling
- Audit logging for compliance
