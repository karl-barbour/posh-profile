# Get repo location
$repoLocation = [System.Environment]::GetEnvironmentVariable('poshProfile', 'User')
if ([string]::IsNullOrEmpty($repoLocation)) {
  Write-Host "`$env:PoshProfile is empty, please run Install-Profile.ps1 manually to set it again" -ForegroundColor Red
  exit 1
}

# Set profile
oh-my-posh init pwsh --config (Join-Path $repoLocation "posh\.mytheme.omp.json") | Invoke-Expression

# Import toolbox
Import-Module (Join-Path $repoLocation "toolbox\output\Toolbox.psd1") -Force

# Install fonts
foreach ($FontItem in (Get-ChildItem -Path $(Join-Path $repoLocation "fonts") | Where-Object {
  ($_.Name -like '*.ttf') -or ($_.Name -like '*.OTF')
    })) {
  Install-Font $FontItem
}

# Update WindowsTerminal settings
Copy-Item (Join-Path $repoLocation "windowsterminal\settings.json") "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Check if $env:TEMP\poshprofile.txt exists - Create with current timestamp if not, or compare to current timestamp if so - only update if no file or >24h
$tempFilePath = "$($env:TEMP)\poshprofile.txt"
$updateNeeded = $false
if ((Test-Path $tempFilePath) -eq $false) {
  New-Item -Path $tempFilePath
  Get-Date -Format "yyyy-MM-ddTHH:mm:ss" | Out-File $tempFilePath
  $updateNeeded = $true
}
else {
  $oldDate = [datetime]::ParseExact((Get-Content $tempFilePath), "yyyy-MM-ddTHH:mm:ss", $null)
  $newDate = Get-Date
  $dateDiff = $newDate - $oldDate
  if ($dateDiff.Days -ge 1) {
    $updateNeeded = $true
  }
}

if ($updateNeeded -eq $true) {
  # Install or upgrade oh-my-posh
  Write-Host "Installing/Upgrading OhMyPosh:"
  if ((($(winget list JanDeDobbeleer.OhMyPosh) -join "") -match ".*No installed package.*") -eq $true) {
    winget install JanDeDobbeleer.OhMyPosh -s winget
  }
  else {
    winget upgrade JanDeDobbeleer.OhMyPosh -s winget
  }


  # Update modules
  $ManagedModules = @(
    "Az.Resources",
    "AWS.Tools.Installer",
    "Microsoft.Graph" #https://www.powershellgallery.com/packages/Microsoft.Graph/
  )

  $ManagedModulesForce = @(
    ## Modules that require a -Force parameter for install
  )

  $TrustedRepositories = @(
    "PSGallery"
  )

  $AWSModules = @(
    "AWS.Tools.CloudFormation",
    "AWS.Tools.EC2",
    "AWS.Tools.S3",
    "AWS.Tools.RDS",
    "AWS.Tools.SSO",
    "AWS.Tools.SSOOIDC"
  )

  Write-Output "Modules managed by this profile:"
  foreach ($managedModule in $ManagedModules) {
    Write-Output "- $managedModule"
  }

  Write-Output "AWSModules managed by this profile:"
  foreach ($AWSModule in $AWSModules) {
    Write-Output "- $AWSModule"
  }

  Write-Output "`nRepositories trusted by this profile:"
  foreach ($repository in $TrustedRepositories) {
    Write-Output "- $repository"
  }

  foreach ($repository in $TrustedRepositories) {
    if ((Get-PSRepository -Name $repository).InstallationPolicy -eq "Untrusted") {
      Write-Output "Setting $repository to trusted status`n"
      Set-PSRepository -Name $repository -InstallationPolicy Trusted
    }
  }

  foreach ($module in $ManagedModules) {
    Write-Output "`nInstalling/Updating $module"
    try {
      Get-InstalledModule -Name $module -ErrorAction Stop | Out-Null
      Write-Output "$module installed. Checking for updates."
      Update-Module -Name $module -Confirm:$false -Scope CurrentUser -Force
    }
    catch {
      Write-Output "$module not installed. Installing."
      Install-Module -Name $module -Confirm:$false -Scope CurrentUser
    }
  }

  foreach ($module in $ManagedModulesForce) {
    Write-Output "`nInstalling/Updating $module"
    try {
      Get-InstalledModule -Name $module -ErrorAction Stop | Out-Null
      Write-Output "$module installed. Checking for updates."
      Update-Module -Name $module -Confirm:$false -Scope CurrentUser
    }
    catch {
      Write-Output "$module not installed. Installing."
      Install-Module -Name $module -Force -Confirm:$false -Scope CurrentUser
    }
  }

  # foreach ($module in $AWSModules) {
  #   Write-Output "`nInstalling/Updating $module"
  #   try {
  #     Get-InstalledModule -Name $module -ErrorAction Stop | Out-Null
  #     Write-Output "$module installed. Checking for updates."
  #     Update-AWSToolsModule -Name $module -Confirm:$false -Scope CurrentUser -CleanUp
  #   }
  #   catch {
  #     Write-Output "$module not installed. Installing."
  #     Install-AWSToolsModule -Name $module -Confirm:$false -Scope CurrentUser -CleanUp
  #   }
  # }

  Write-Host "Installing missing AWS Modules"
  Install-AWSToolsModule $AWSModules -CleanUp -Force

  Write-Host "Updating AWS Modules"
  Update-AWSToolsModule -CleanUp -Force

  Get-Date -Format "yyyy-MM-ddTHH:mm:ss" | Out-File $tempFilePath
}
else {
  Write-Host "Skipping module updates (last updated $($dateDiff) ago at $($oldDate))"
}

# Import modules
$ImportModules = @(
  "AWS.Tools.Installer",
  "AWS.Tools.SSO",
  "AWS.Tools.SSOOIDC"
)

Write-Host "`nImporting modules: $ImportModules"
Import-Module -Name $ImportModules

