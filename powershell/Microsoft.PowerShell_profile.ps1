# Variables
$repoLocation = "G:\git\posh-profile"

# Install posh if not found
if (Get-Module -ListAvailable -Name oh-my-posh) {
  Import-Module -Name oh-my-posh
}
else {
  Write-Host "Oh-My-Posh not found - installing!"
  Install-Module oh-my-posh -Scope CurrentUser -Force
}

# Set profile
Set-PoshPrompt -Theme (Join-Path $repoLocation "posh\.mytheme.omp.json")

# Import toolbox
Import-Module (Join-Path $repoLocation "toolbox\output\Toolbox.psm1")

# Install fonts
foreach ($FontItem in (Get-ChildItem -Path $(Join-Path $repoLocation "fonts") | Where-Object {
  ($_.Name -like '*.ttf') -or ($_.Name -like '*.OTF')
    })) {
  Install-Font $FontItem
}

# Update WindowsTerminal settings
Copy-Item (Join-Path $repoLocation "windowsterminal\settings.json") "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Update modules
$ManagedModules = @(
  "Az.Resources",
  "AWSPowerShell.NetCore",
  "Microsoft.Graph" #https://www.powershellgallery.com/packages/Microsoft.Graph/
)

$ManagedModulesForce = @(
  ## Modules that require a -Force parameter for install
)

$TrustedRepositories = @(
  "PSGallery"
)

Write-Output "Modules managed by this profile:"
foreach ($managedModule in $ManagedModules) {
  Write-Output "- $managedModule"
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
    Update-Module -Name $module -Confirm:$false
  }
  catch {
    Write-Output "$module not installed. Installing."
    Install-Module -Name $module -Confirm:$false
  }
}

foreach ($module in $ManagedModulesForce) {
  Write-Output "`nInstalling/Updating $module"
  try {
    Get-InstalledModule -Name $module -ErrorAction Stop | Out-Null
    Write-Output "$module installed. Checking for updates."
    Update-Module -Name $module -Confirm:$false
  }
  catch {
    Write-Output "$module not installed. Installing."
    Install-Module -Name $module -Force -Confirm:$false
  }
}

# Import modules
$ImportModules = @(
  "AWSPowerShell.NetCore"
)

Write-Host "`nImporting modules: $ImportModules"
Import-Module -Name $ImportModules
