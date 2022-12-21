function Get-CommandInfo {
  <#
  .SYNOPSIS
      Get-Command helper.
  .DESCRIPTION
      Get-Command helper.
  #>

  [CmdletBinding()]
  param (
      # The name of a command.
      [Parameter(Mandatory, ParameterSetName = 'ByName')]
      [String]$Name,

      # A CommandInfo object.
      [Parameter(Mandatory, ParameterSetName = 'FromCommandInfo')]
      [System.Management.Automation.CommandInfo]$CommandInfo,

      # If a module name is specified the private / internal scope of the module will be searched.
      [String]$ModuleName,

      # Claims and discards any other supplied arguments.
      [Parameter(ValueFromRemainingArguments, DontShow)]
      $EaterOfArgs
  )

  if ($Name) {
      if ($ModuleName) {
          try {
              if (-not ($moduleInfo = Get-Module $ModuleName)) {
                  $moduleInfo = Import-Module $ModuleName -Global -PassThru
              }
              $CommandInfo = & $moduleInfo ([ScriptBlock]::Create('Get-Command {0}' -f $Name))
          }
          catch {
              $pscmdlet.ThrowTerminatingError($_)
          }
      }
      else {
          $CommandInfo = Get-Command -Name $Name
      }
  }

  if ($CommandInfo -is [System.Management.Automation.AliasInfo]) {
      $CommandInfo = $CommandInfo.ResolvedCommand
  }

  return $CommandInfo
}

function Get-RandomString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateRange(12, [int]::MaxValue)]
        [int]
        $StringLength,
        [int]
        $SpecialCharacters = 4
    )
    process {
        foreach ($randomString in $StringLength) {
            $chars = ((65..90) + (97..122) | ForEach-Object { $_ -as [char]})
            $specialChars = ((33..46) | ForEach-Object { $_ -as [char]})
            $outputString = $chars | Get-Random -Count ($StringLength - $SpecialCharacters)
            $outputString += $SpecialChars | Get-Random -Count $SpecialCharacters
            -join ($outputString | Get-Random -Count $StringLength)
        }
    }
}

function Get-Syntax {
    <#
    .SYNOPSIS
        Get the syntax for a command.
    .DESCRIPTION
        Get the syntax for a command. A wrapper for Get-Command -Syntax.
    #>

    [CmdletBinding()]
    [Alias('synt', 'syntax')]
    param (
        # The name of a command.
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [String]$Name,

        # A CommandInfo object.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromCommandInfo')]
        [System.Management.Automation.CommandInfo]$CommandInfo,

        # Write syntax in the short format used by Get-Command.
        [Switch]$Short
    )

    begin {
        $commonParams = @(
            [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
            [System.Management.Automation.Internal.ShouldProcessParameters].GetProperties().Name
            [System.Management.Automation.Internal.TransactionParameters].GetProperties().Name
        )
    }

    process {
        $CommandInfo = Get-CommandInfo @psboundparameters
        foreach ($parameterSet in $CommandInfo.ParameterSets) {
            if ($Short) {
                "`n{0} {1}" -f $CommandInfo.Name, $parameterSet
            }
            else {
                $stringBuilder = [System.Text.StringBuilder]::new().AppendFormat('{0} ', $commandInfo.Name)

                $null = foreach ($parameter in $parameterSet.Parameters) {
                    if ($parameter.Name -notin $commonParams) {
                        if (-not $parameter.IsMandatory) {
                            $stringBuilder.Append('[')
                        }

                        if ($parameter.Position -gt [Int32]::MinValue) {
                            $stringBuilder.Append('[')
                        }

                        $stringBuilder.AppendFormat('-{0}', $parameter.Name)

                        if ($parameter.Position -gt [Int32]::MinValue) {
                            $stringBuilder.Append(']')
                        }

                        if ($parameter.ParameterType -ne [Switch]) {
                            $stringBuilder.AppendFormat(' <{0}>', $parameter.ParameterType.Name)
                        }

                        if (-not $parameter.IsMandatory) {
                            $stringBuilder.Append(']')
                        }

                        $stringBuilder.AppendLine().Append(' ' * ($commandInfo.Name.Length + 1))
                    }
                }

                $stringBuilder.AppendLine().ToString()
            }
        }
    }
}

function Install-Font {
	<#
	.SYNOPSIS
		Install the font
	
	.DESCRIPTION
		This function will attempt to install the font by copying it to the c:\windows\fonts directory and then registering it in the registry. This also outputs the status of each step for easy tracking. 
	
	.PARAMETER FontFile
		Name of the Font File to install

	.PARAMETER Verbose
		Outputs status
	
	.EXAMPLE
		Install-Font -FontFile $value1

	.EXAMPLE
		Install-Font -FontFile $value1 -Verbose
	
	.NOTES
		Additional information about the function.
	#>
	param
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$FontFile
	)
	
	#Get Font Name from the File's Extended Attributes
	$oShell = new-object -com shell.application
	$Folder = $oShell.namespace($FontFile.DirectoryName)
	$Item = $Folder.Items().Item($FontFile.Name)
	$FontName = $Folder.GetDetailsOf($Item, 21)
	try {
		switch ($FontFile.Extension) {
			".ttf" { $FontName = $FontName + [char]32 + '(TrueType)' }
			".otf" { $FontName = $FontName + [char]32 + '(OpenType)' }
		}
		$Copy = $true
		if ($Verbose) { Write-Host ('Copying' + [char]32 + $FontFile.Name + '.....') -NoNewline }
		Copy-Item -Path $fontFile.FullName -Destination ("C:\Windows\Fonts\" + $FontFile.Name) -Force
		#Test if font is copied over
		If ((Test-Path ("C:\Windows\Fonts\" + $FontFile.Name)) -eq $true -and $Verbose) {
			Write-Host ('Success') -Foreground Yellow
		}
		else {
			Write-Host ('Failed') -ForegroundColor Red
		}
		$Copy = $false
		#Test if font registry entry exists
		If ((Get-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue) -ne $null) {
			#Test if the entry matches the font file name
			If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
				if ($Verbose) { 
					Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline
					Write-Host ('Success') -ForegroundColor Yellow
				}
			}
			else {
				$AddKey = $true
				Remove-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
				if ($Verbose) { Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline }
				New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
				If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name -and $Verbose) {
					Write-Host ('Success') -ForegroundColor Yellow
				}
				else {
					Write-Host ('Failed') -ForegroundColor Red
				}
				$AddKey = $false
			}
		}
		else {
			$AddKey = $true
			if ($Verbose) { Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline }
			New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
			If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name -and $Verbose) {
				Write-Host ('Success') -ForegroundColor Yellow
			}
			else {
				Write-Host ('Failed') -ForegroundColor Red
			}
			$AddKey = $false
		}
		
	}
 catch {
		If ($Copy -eq $true) {
			if ($Verbose) { Write-Host ('Failed') -ForegroundColor Red }
			$Copy = $false
		}
		If ($AddKey -eq $true) {
			if ($Verbose) { Write-Host ('Failed') -ForegroundColor Red }
			$AddKey = $false
		}
		if ($Verbose) { write-warning $_.exception.message }
	}
	if ($Verbose) { Write-Host }
}

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
      Set-AWSCredential -ProfileName $($profiles[$selection]) -Scope Global
      Write-Host "Selected $($ENV:AWS_PROFILE)"
    }
    else {
      Write-Error "Profile parameter not found and ~/.aws/config does not exist"
    }
  }
}

# Set an alias too... because why not
Set-Alias awsprofile Set-AWSProfile

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

function Watch-CFNStack {
    <#
	.SYNOPSIS
		Polls a CloudFormation stack and returns latest events and status
	
	.DESCRIPTION
		This function will poll a CloudFormation stack and return latest events and status code in host terminal.

	.PARAMETER StackName
		Name of CFN Stack to poll

	.PARAMETER EventCount
		(OPTIONAL) How many events to return - Default 30

	.PARAMETER SleepTime
		(OPTIONAL) Time in seconds to sleep between API calls - Default 5
	
	.EXAMPLE
		Watch-CFNStack -StackName MyStack

    .EXAMPLE
		Watch-CFNStack -StackName MyStack -EventCount 10 -SleepTime 15
	
	.NOTES
		Requires AWSPowerShell.NetCore - Uses environment variables for credentials.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $StackName,

        [Parameter()]
        [Int32]
        $EventCount = 30,

        [Parameter()]
        [Int32]
        $SleepTime = 5
    )

    $green = @("CREATE_COMPLETE", "DELETE_COMPLETE", "IMPORT_COMPLETE", "IMPORT_ROLLBACK_COMPLETE", "ROLLBACK_COMPLETE", "UPDATE_COMPLETE", "UPDATE_ROLLBACK_COMPLETE")
    $red = @("CREATE_FAILED", "DELETE_FAILED", "IMPORT_ROLLBACK_FAILED", "ROLLBACK_FAILED", "UPDATE_FAILED", "UPDATE_ROLLBACK_FAILED")
    $magenta = @("UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS", "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS")

    while ($true) { 
        Get-CFNStackEvents -StackName $stackName -NoAutoIteration | Select-Object -First 30 | out-host 
        $status = (Get-CFNStack -StackName $stackName).StackStatus.Value 
    
        if ($green -contains $status) {
            $color = "Green"
        }
        elseif ($red -contains $status) {
            $color = "Red"
        }
        elseif ($magenta -contains $status) {
            $color = "Magenta"
        }
        else {
            $color = "Yellow"
        }

        Write-Host "[$(Get-Date)] Stack $stackName is in state $status" -ForegroundColor $color
        Start-Sleep 5
    }
}

