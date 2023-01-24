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
	$oShell = New-Object -com shell.application
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
		if ($Verbose) { Write-Warning $_.exception.message }
	}
	if ($Verbose) { Write-Host }
}
