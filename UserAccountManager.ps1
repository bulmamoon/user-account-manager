<#
.SYNOPSIS
    IT Help Desk - User Account Manager
.DESCRIPTION
    A PowerShell script for managing local user accounts, simulating common
    Active Directory tasks performed by IT Help Desk staff. Supports creating,
    disabling, unlocking, resetting passwords, and auditing user accounts.

    NOTE: This script uses local Windows accounts to simulate AD operations.
    In a real environment, replace Get-LocalUser/New-LocalUser calls with
    Get-ADUser/New-ADUser from the ActiveDirectory module.

.NOTES
    Author: IT Help Desk Team
    Version: 1.0
    Requires: PowerShell 5.1+ | Run as Administrator for account operations
#>

#Requires -Version 5.1

# âââ Configuration ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
$LogFile    = ".\UserAccountManager.log"
$ExportFile = ".\account_audit.csv"

# âââ Logging ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry
    switch ($Level) {
        "INFO"    { Write-Host $entry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $entry -ForegroundColor Green }
        "WARN"    { Write-Host $entry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $entry -ForegroundColor Red }
    }
}

# âââ Helper: Prompt with validation âââââââââââââââââââââââââââââââââââââââââââ
function Prompt-Input {
    param([string]$Label, [bool]$Required = $true)
    do {
        $val = Read-Host "  $Label"
    } while ($Required -and [string]::IsNullOrWhiteSpace($val))
    return $val.Trim()
}

# âââ 1. Create New User ââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
function New-HelpDeskUser {
    Write-Host "`n=== CREATE NEW USER ACCOUNT ===" -ForegroundColor Magenta
    $firstName   = Prompt-Input "First Name"
    $lastName    = Prompt-Input "Last Name"
    $username    = Prompt-Input "Username (e.g. jsmith)"
    $department  = Prompt-Input "Department"
    $description = "$firstName $lastName - $department"
    $password    = Read-Host "  Set Password" -AsSecureString

    try {
        New-LocalUser -Name $username `
                      -Password $password `
                      -FullName "$firstName $lastName" `
                      -Description $description `
                      -PasswordNeverExpires:$false `
                      -UserMayNotChangePassword:$false `
                      -ErrorAction Stop

        # Add to standard 'Users' group
        Add-LocalGroupMember -Group "Users" -Member $username -ErrorAction SilentlyContinue

        Write-Log "Created user account: $username ($firstName $lastName) in $department" "SUCCESS"
        Write-Host "`n  [OK] User '$username' created successfully." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to create user $username : $_" "ERROR"
    }
}

# âââ 2. Disable User Account ââââââââââââââââââââââââââââââââââââââââââââââââââ
function Disable-HelpDeskUser {
    Write-Host "`n=== DISABLE USER ACCOUNT ===" -ForegroundColor Magenta
    $username = Prompt-Input "Username to disable"
    try {
        Disable-LocalUser -Name $username -ErrorAction Stop
        Write-Log "Disabled user account: $username" "SUCCESS"
        Write-Host "  [OK] Account '$username' has been disabled." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to disable $username : $_" "ERROR"
    }
}

# âââ 3. Enable / Unlock User Account âââââââââââââââââââââââââââââââââââââââââ
function Enable-HelpDeskUser {
    Write-Host "`n=== ENABLE / UNLOCK USER ACCOUNT ===" -ForegroundColor Magenta
    $username = Prompt-Input "Username to enable/unlock"
    try {
        Enable-LocalUser -Name $username -ErrorAction Stop
        Write-Log "Enabled/unlocked user account: $username" "SUCCESS"
        Write-Host "  [OK] Account '$username' has been enabled." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to enable $username : $_" "ERROR"
    }
}

# âââ 4. Reset Password ââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
function Reset-HelpDeskPassword {
    Write-Host "`n=== RESET USER PASSWORD ===" -ForegroundColor Magenta
    $username    = Prompt-Input "Username"
    $newPassword = Read-Host "  New Password" -AsSecureString
    try {
        Set-LocalUser -Name $username -Password $newPassword -ErrorAction Stop
        Write-Log "Password reset for user: $username" "SUCCESS"
        Write-Host "  [OK] Password for '$username' has been reset." -ForegroundColor Green
        Write-Host "  Remind the user to change their password on next login." -ForegroundColor Yellow
    }
    catch {
        Write-Log "Failed to reset password for $username : $_" "ERROR"
    }
}

# âââ 5. View User Details âââââââââââââââââââââââââââââââââââââââââââââââââââââ
function Get-HelpDeskUser {
    Write-Host "`n=== VIEW USER DETAILS ===" -ForegroundColor Magenta
    $username = Prompt-Input "Username"
    try {
        $user = Get-LocalUser -Name $username -ErrorAction Stop
        Write-Host "`n  ----------------------------------------" -ForegroundColor Cyan
        Write-Host "  Username        : $($user.Name)"
        Write-Host "  Full Name       : $($user.FullName)"
        Write-Host "  Description     : $($user.Description)"
        Write-Host "  Enabled         : $($user.Enabled)"
        Write-Host "  Last Logon      : $($user.LastLogon)"
        Write-Host "  Password Set    : $($user.PasswordLastSet)"
        Write-Host "  Account Expires : $($user.AccountExpires)"
        Write-Host "  ----------------------------------------" -ForegroundColor Cyan

        # Show group memberships
        $groups = Get-LocalGroup | Where-Object {
            (Get-LocalGroupMember -Group $_.Name -ErrorAction SilentlyContinue).Name -contains "$env:COMPUTERNAME\$username"
        }
        Write-Host "  Group Memberships:"
        $groups | ForEach-Object { Write-Host "    - $($_.Name)" }
    }
    catch {
        Write-Log "Could not find user $username : $_" "ERROR"
    }
}

# âââ 6. List All Users ââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
function Get-AllUsers {
    Write-Host "`n=== ALL LOCAL USER ACCOUNTS ===" -ForegroundColor Magenta
    $users = Get-LocalUser | Select-Object Name, FullName, Enabled, LastLogon, PasswordLastSet
    $users | Format-Table -AutoSize
    Write-Host "  Total: $($users.Count) account(s)"
}

# âââ 7. Bulk Create from CSV âââââââââââââââââââââââââââââââââââââââââââââââââ
function New-BulkUsers {
    Write-Host "`n=== BULK USER CREATION FROM CSV ===" -ForegroundColor Magenta
    $csvPath = Prompt-Input "Path to CSV file (or press Enter for 'users_template.csv')"
    if ([string]::IsNullOrWhiteSpace($csvPath)) { $csvPath = ".\users_template.csv" }

    if (-not (Test-Path $csvPath)) {
        Write-Log "CSV file not found: $csvPath" "ERROR"
        return
    }

    $users = Import-Csv -Path $csvPath
    $count = 0
    foreach ($u in $users) {
        try {
            $securePass = ConvertTo-SecureString $u.Password -AsPlainText -Force
            New-LocalUser -Name $u.Username `
                          -Password $securePass `
                          -FullName "$($u.FirstName) $($u.LastName)" `
                          -Description "$($u.FirstName) $($u.LastName) - $($u.Department)" `
                          -ErrorAction Stop
            Add-LocalGroupMember -Group "Users" -Member $u.Username -ErrorAction SilentlyContinue
            Write-Log "Bulk created: $($u.Username)" "SUCCESS"
            $count++
        }
        catch {
            Write-Log "Failed to create $($u.Username): $_" "ERROR"
        }
    }
    Write-Host "`n  [OK] Bulk creation complete. $count account(s) created." -ForegroundColor Green
}

# âââ 8. Export Audit Report ââââââââââââââââââââââââââââââââââââââââââââââââââ
function Export-AuditReport {
    Write-Host "`n=== EXPORTING ACCOUNT AUDIT REPORT ===" -ForegroundColor Magenta
    $users = Get-LocalUser | Select-Object Name, FullName, Enabled, LastLogon, PasswordLastSet, AccountExpires, Description
    $users | Export-Csv -Path $ExportFile -NoTypeInformation
    Write-Log "Audit report exported to $ExportFile" "SUCCESS"
    Write-Host "  [OK] Report saved to: $ExportFile" -ForegroundColor Green
}

# âââ Main Menu ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
function Show-Menu {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   IT HELP DESK - USER ACCOUNT MANAGER" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  1. Create new user account"
    Write-Host "  2. Disable user account"
    Write-Host "  3. Enable / Unlock user account"
    Write-Host "  4. Reset user password"
    Write-Host "  5. View user details"
    Write-Host "  6. List all users"
    Write-Host "  7. Bulk create users from CSV"
    Write-Host "  8. Export account audit report"
    Write-Host "  9. Exit"
    Write-Host "------------------------------------------------" -ForegroundColor Cyan
}

# âââ Entry Point ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
Write-Log "UserAccountManager started by $env:USERNAME on $env:COMPUTERNAME"

do {
    Show-Menu
    $choice = Read-Host "`n  Select an option [1-9]"
    switch ($choice) {
        "1" { New-HelpDeskUser }
        "2" { Disable-HelpDeskUser }
        "3" { Enable-HelpDeskUser }
        "4" { Reset-HelpDeskPassword }
        "5" { Get-HelpDeskUser }
        "6" { Get-AllUsers }
        "7" { New-BulkUsers }
        "8" { Export-AuditReport }
        "9" { Write-Host "`n  Exiting. Goodbye!`n" -ForegroundColor Cyan }
        default { Write-Host "  Invalid option. Try again." -ForegroundColor Yellow }
    }
} while ($choice -ne "9")
