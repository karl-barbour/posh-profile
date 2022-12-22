function Clear-PoshUpdate {
    <#
    .SYNOPSIS
      Clear last profile update time.
    .DESCRIPTION
      Clear last profile update time.
    #>

    $path = "$($env:temp)\poshprofile.txt"
    try { 
        Remove-Item $path -Force -ErrorAction Stop
        Write-Host "$path cleared"
    }
    catch {
        Write-Host "$path does not exist"
    }
}

Set-Alias -Name clu -Value Clear-PoshUpdate