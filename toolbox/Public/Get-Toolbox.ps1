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
        Get-ChildItem (Join-Path $repoPath "toolbox/public") | Format-Table Name
    }
}

Set-Alias -Name toolbox -Value Get-Toolbox