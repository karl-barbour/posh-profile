function Get-Toolbox {
  <#
    .SYNOPSIS
      Gets commands in the toolbox
    .DESCRIPTION
      Gets commands in the toolbox
    #>

  $repoPath = [System.Environment]::GetEnvironmentVariable('poshProfile', 'User')
  if ([string]::IsNullOrEmpty($repoPath)) {
    Write-Host "`$env:PoshProfile is empty, please run Install-Profile.ps1 manually to set it again" -ForegroundColor Red
  }
  else {
    $commands = (Get-ChildItem (Join-Path $repoPath "toolbox/public")).Name -Replace ".ps1", ""
    $aliases = @{
      "Clear-PoshUpdate"   = "clu";
      "Update-PoshProfile" = "upp";
      "Get-Toolbox"        = "toolbox";
      "Set-AWSProfile"     = "awsprofile";
      "Set-AWSRegion"      = "awsregion"
    }
    

    $commands | ForEach-Object { try { $aliases.Add($_, "") } catch {} }

    $aliases.GetEnumerator() | Sort-Object -Property Name
  }
}

Set-Alias -Name toolbox -Value Get-Toolbox -Scope Global