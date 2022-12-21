function New-SSMConnection {
  <#
  .SYNOPSIS
      New-SSMConnection opens an RDP tunnel using SSM.
  .DESCRIPTION
      Requires awscli and SSM extension.
  .PARAMETER Profile
      AWS Profile Name.
  .PARAMETER Region
      AWS Region.
  .PARAMETER PEMFile
      Path to PEM file to decrypt passwords (Optional).
  .PARAMETER InstanceId
      Specify instance ID (Optional).
  .PARAMETER LocalPort
      Specify Local Port to forward (Optional).
  .PARAMETER RemotePort
      Specify Remote Port to forward (Optional - Default 3389).
  .EXAMPLE
      New-SSMConnection -Profile profilename -Region eu-west-1
  .EXAMPLE
      New-SSMConnection -Profile profilename -Region eu-west-1 -PEMFile ./key.pem
  .EXAMPLE
      New-SSMConnection -Profile profilename -Region eu-west-1 -InstanceId "i-12345678abcdef" -PEMFile ./key.pem
  .EXAMPLE
      New-SSMConnection -Profile profilename -Region eu-west-1 -LocalPort 56789 -RemotePort 22
  #>

  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [string]
    $Profile,

    [Parameter(Mandatory = $false)]
    [string]
    $Region,

    [Parameter(Mandatory = $false)]
    [string]
    $PEMFile,

    [Parameter(Mandatory = $false)]
    [string]
    $InstanceId,

    [Parameter(Mandatory = $false)]
    [string]
    $LocalPort,

    [Parameter(Mandatory = $false)]
    [string]
    $RemotePort = "3389"
  )

  # Functions
  function Get-Timestamp {
    return "[$(Get-Date)]"  
  }


  # Test AWSCLI is installed
  try {
    $testCli = Get-Command "aws" -ErrorAction Stop
  }
  catch {
    Write-Error "AWS CLI is not installed/not found in path - visit https://aws.amazon.com/cli/ for instructions" -ErrorAction Stop
  }

  # Import module
  Import-Module AWS.Tools.EC2

  # Set credentials if passed
  if ($profile) {
    try {
      Set-AWSCredentials -ProfileName $profile
    }
    catch {
      Write-Error "Unable to load profile: $_" -ErrorAction Stop
    }
  }
  else {
    if ($env:AWS_ACCESS_KEY_ID) {
      $Profile = "envVars"
    }
    else {
      Write-Host "$(Get-Timestamp) ERROR: Could not find AWS credentials in env vars or parameters" -ForegroundColor Red
    }
  }

  if ($region) {
    Set-DefaultAWSRegion $Region
  }
  else {
    if ($env:AWS_DEFAULT_REGION) {
      $Region = $env:AWS_DEFAULT_REGION
    }
    else {
      Write-Host "$(Get-Timestamp) ERROR: Could not find AWS region in env vars or parameters" -ForegroundColor Red
    }
  }

  if ($Profile -and $Region) {

    Write-Host "$(Get-Timestamp) Initialised with profile $($profile) in region $($region)"

    # Get instances
    if ([string]::IsNullOrEmpty($InstanceId)) {
      Write-Host "$(Get-Timestamp) Getting running instances..."
      try { 
        $ec2Instances = (Get-EC2Instance).Instances | Where-Object { $_.State.Name -eq "running" }
      }
      catch {
        Write-Error "Could not get instances: $_" -ErrorAction Stop
      }

      # Display for selection
      Write-Host "$(Get-Timestamp) Got $($ec2Instances.Count) running instances:"
      $instanceOutput = @()
      $count = 0
      foreach ($instance in $ec2Instances) {
        try {
          $name = ($instance.Tags | Where-Object { $_.Key -eq "Name" }).Value
        }
        catch {
          $name = ""
        }
        $instanceSplat = NEw-Object -TypeName PSObject -Property @{
          Index      = $count
          InstanceId = $instance.InstanceId
          Name       = $name
          State      = $instance.State.Name
          LaunchTime = $instance.LaunchTime
        }
        $instanceOutput += $instanceSplat  
        $count++
      }

      $instanceOutput | Format-Table Index, InstanceId, Name, State, LaunchTime

      # Get selection
      $selectionInstance = Read-Host -Prompt "$(Get-Timestamp) Enter index of instance to connect to"
      if ($selectionInstance -eq "") {
        Write-Host "$(Get-Timestamp) No instance selected, exiting"
        return
      }
      else {
        $InstanceId = $instanceOutput[$selectionInstance].InstanceId
      }
    } 

    # Ask for port
    if ([string]::IsNullOrEmpty($LocalPort)) {
      $selectionPort = Read-Host -Prompt "$(Get-Timestamp) Enter local port to forward (Press enter to accept default: 56789)"
      if ($selectionPort -eq "") { $selectionPort = "56789" }
      $LocalPort = $selectionPort
    }

    # Retrieve password if PEM param
    if ($PEMFile) {
      Write-Host "$(Get-Timestamp) -PEMFile parameter detected, attepting to get password..."

      if ((Test-Path $PEMFile) -ne $true) {
        Write-Host "$(Get-Timestamp) Could not find $($PEMFile), skipping..."
      }
      else {
        $password = Get-EC2PasswordData -InstanceId $InstanceId -PEMFile $PEMFile -Decrypt
        if ([string]::IsNullOrEmpty($password)) {
          Write-Host "$(Get-Timestamp) Could not decrypt password, continuing without."
        }
        else {
          Write-Host "$(Get-Timestamp) Successfully decrypted password."
        }
      }
    }

    # Output selection
    Write-Host "$(Get-Timestamp) Selected:"
    Write-Host "Instance ID: $($InstanceId)"
    Write-Host "Local port: $($LocalPort)"
    if ([string]::IsNullOrEmpty($password) -ne $true) { Write-Host "Password: $($password)" }

    # Start SSM connection
    Write-Host "$(Get-Timestamp) Attempting to start SSM connection:"

    if ($profile -ne "envVars") {
      aws ssm start-session --target $InstanceId --document-name AWS-StartPortForwardingSession --parameters "localPortNumber=$($LocalPort),portNumber=$($RemotePort)" --region $Region --profile $Profile
    }
    else {
      aws ssm start-session --target $InstanceId --document-name AWS-StartPortForwardingSession --parameters "localPortNumber=$($LocalPort),portNumber=$($RemotePort)" --region $Region
    }

    Write-Host "$(Get-Timestamp) Connection terminated."
  }
}