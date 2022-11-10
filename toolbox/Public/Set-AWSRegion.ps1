function Set-AWSRegion {
  <#
  .SYNOPSIS
      Set-AWSRegiopn
  .DESCRIPTION
      Sets $ENV:AWS_REGION for lazy people. 
  .PARAMETER Region
      Specify a profile's name. Optional.
  .EXAMPLE
      Set-AWSRegion eu-west-1
  .EXAMPLE
      awsregion eu-west-1
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]
    $Region
  )

  if ($Region) {
    # Use the parameter if it's there...
    $ENV:AWS_DEFAULT_REGION = $Region
    Set-DefaultAWSRegion $Region -Scope Global
  }
  else {
    $regions = @(
      "af-south-1", "ap-east-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", "ca-central-1", "eu-central-1", "eu-north-1", "eu-south-1", "eu-west-1", "eu-west-2", "eu-west-3", "me-south-1", "sa-east-1", "us-east-1", "us-east-2", "us-west-1", "us-west-2"
    )
    $regions = $regions | Sort-Object

    # Iterate through profiles and display
    for ($i = 0; $i -lt $regions.count; $i++) {
      Write-Host "$($i): $($regions[$i])"
    }

    # Ask for selection and set as env var
    $selection = Read-Host "Choose a region"
    $ENV:AWS_DEFAULT_REGION = $($regions[$selection])
    Set-DefaultAWSRegion $($regions[$selection]) -Scope Global
    Write-Host "Selected $($ENV:AWS_DEFAULT_REGION)"
  }
}

# Set an alias too... because why not
Set-Alias awsregion Set-AWSRegion