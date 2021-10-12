function Set-AWSRegion {
  <#
  .SYNOPSIS
      Set-AWSRegiopn
  .DESCRIPTION
      Sets $ENV:AWS_REGION for lazy people. C
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
    $ENV:AWS_REGION = $Region
  }
  else {
    Write-Error "Must specify a region"
  }
}

# Set an alias too... because why not
Set-Alias awsregion Set-AWSRegion