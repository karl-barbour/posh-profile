# Variables
$repoLocation = "G:\git\posh-profile"

# Install posh if not found
if (Get-Module -ListAvailable -Name oh-my-posh) {
  Import-Module -Name oh-my-posh
} else {
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

# Import modules
if ((Get-Module AWSPowerShell.NetCore) -eq $null) { Import-Module AWSPowerShell.NetCore -Scope Global }