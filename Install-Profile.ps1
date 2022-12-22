# Set environment variable to remember location
$repoPath = [System.Environment]::GetEnvironmentVariable('poshProfile', 'User')
if ([string]::IsNullOrEmpty($repoPath)) {
    $repoPath = Split-Path $MyInvocation.MyCommand.Path
    [System.Environment]::SetEnvironmentVariable('poshProfile', $repoPath, 'User')
    Write-Host "System Environment Variable (scope:user) poshProfile set to $repoPath"
}

# Copy profile 
$profilePath = Join-Path $repoPath "powershell/Microsoft.PowerShell_profile.ps1"
Copy-Item $profilePath $PROFILE

Write-Host "Profile installed to $PROFILE"

# dot source profile
. $PROFILE