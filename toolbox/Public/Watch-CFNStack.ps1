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