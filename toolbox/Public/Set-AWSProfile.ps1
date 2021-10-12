function Set-AWSProfile {
  <#
  .SYNOPSIS
      Set-AWSProfile
  .DESCRIPTION
      Sets $ENV:AWS_PROFILE for lazy people. Can pass in a profile name, or read ~/.aws/config for all available.
  .PARAMETER Profile
      Specify a profile's name. Optional.
  .EXAMPLE
      Set-AWSProfile
  .EXAMPLE
      awsprofile
  .EXAMPLE
      Set-AWSProfile myprofile
  .EXAMPLE
      Set-AWSProfile -Profile myprofile
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]
    $Profile
  )

  if ($Profile) {
    # Use the parameter if it's there...
    $ENV:AWS_PROFILE = $Profile
  }
  else {
    # If no profile param, list all profiles and offer selection
    if (Test-Path "~/.aws/config") {
      $awsconfig = Get-Content "~/.aws/config"
      $profiles = @()
      foreach ($line in $awsconfig) {
        if ($line -match "\[.*\]") { $profiles += $line.replace("[profile ", "").replace("]", "") } # I am very lazy
      }
      $profiles = $profiles | Sort-Object

      # Iterate through profiles and display
      for ($i = 0; $i -lt $profiles.count; $i++) {
        Write-Host "$($i): $($profiles[$i])"
      }

      # Ask for selection and set as env var
      $selection = Read-Host "Choose a profile"
      $ENV:AWS_PROFILE = $($profiles[$selection])
      Write-Host "Selected $($ENV:AWS_PROFILE)"
    } else {
      Write-Error "Profile parameter not found and ~/.aws/config does not exist"
    }
  }
}

# Set an alias too... because why not
Set-Alias awsprofile Set-AWSProfile