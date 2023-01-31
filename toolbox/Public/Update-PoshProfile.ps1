function Update-PoshProfile {
  <#
    .SYNOPSIS
      Clear last profile update time.
    .DESCRIPTION
      Clear last profile update time.
    #>

  $repoPath = [System.Environment]::GetEnvironmentVariable('poshProfile', 'User')
  if ([string]::IsNullOrEmpty($repoPath)) {
    Write-Host "`$env:PoshProfile is empty, please run Install-Profile.ps1 manually to set it again" -ForegroundColor Red
  }
  else {
    & (Join-Path $repoPath "toolbox/Build.ps1")
    & (Join-Path $repoPath "Install-Profile.ps1")
    Write-Host "Open a new terminal to load new toolbox" -ForegroundColor Yellow
  }
}

Set-Alias -Name upp -Value Update-PoshProfile -Scope Global