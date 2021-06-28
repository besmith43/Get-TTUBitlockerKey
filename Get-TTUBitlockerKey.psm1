function Get-TTUBitlockerKey {
    <#
		.SYNOPSIS
            Uses manage-bde to retrieve the Bitlocker recovery key directly from the host
    
		.DESCRIPTION
            Uses Powershell's invoke-command and manage-bde to get the Bitlocker recovery key directly from the host(s), but the machine must be online
    
        .PARAMETER ComputerNames
            This parameter is to set the computer or computers that you need the bitlocker key of.
			
		.EXAMPLE
            Get-TTUBitlockerKey -ComputerNames "HEND001B-M01"

        .EXAMPLE
            gblk -cn "HEND001B-M01", "HEND001B-M02"
    
		.NOTES
			6/28/2021
			-Created
	#>

    param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Alias('cn')]
        [string[]]
        $ComputerNames = $null
    )

    function Test-Hostname {
        param (
            [Parameter(Mandatory=$true)]
            [string]
            $PassedHostname
        )

        if ($(Test-Connection -ComputerName $PassedHostname -quiet))
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    function Get-BitlockerKey {
        param (
            [Parameter(Mandatory=$true)]
            [string]
            $PassedHostname
        )

        $session = New-PSSession -ComputerName $PassedHostname

        if (!$session)
        {
            Write-Error "PSSession failed to $PassedHostname"
            return ""
        }
        
        $password = invoke-command -Session $session -ScriptBlock {
            $content = $(manage-bde C: -protectors -get -type RecoveryPassword)

            try {
                $password = $content[9]

                $password = $password.Trim()
            }
            catch {
                Write-Error "Manage-bde didn't return valid output"
                return ""
            }

            return $password
        }

        return $password
    }

    function Set-Cursor {
        param (
            $CursorPosition
        )
            $host.UI.RawUI.CursorPosition = $CursorPosition
            Write-Host -NoNewline "                                                           "
            $host.UI.RawUI.CursorPosition = $CursorPosition
    }

    # main function
    $BitlockerKeys = New-Object System.Collections.Generic.List[System.Object]

    $ResetPosition = $host.UI.RawUI.CursorPosition

    Write-Host "This may take a minute, so please be patient"
    Start-Sleep -Seconds 1

    foreach($comp in $ComputerNames)
    {
        Set-Cursor -CursorPosition $ResetPosition
        Write-Host -NoNewLine "Testing if $comp is online"

        if (Test-Hostname -PassedHostname $comp)
        {
            Set-Cursor -CursorPosition $ResetPosition
            Write-Host -NoNewLine "$comp is Online.  Getting Bitlocker Key"
            $BitlockerKey = Get-BitlockerKey -PassedHostname $comp
            $BitlockerKeys.Add($BitlockerKey)
        }
        else
        {
            Set-Cursor -CursorPosition $ResetPosition 
            Write-Host "$comp is offline"
            $ResetPosition = $host.UI.RawUI.CursorPosition
        }
    }
        
    Set-Cursor -CursorPosition $ResetPosition
    
    Write-Output $BitlockerKeys.ToArray()
}
Export-ModuleMember -function Get-TTUBitlockerKey
Set-Alias gblk Get-TTUBitlockerKey -scope "Global"