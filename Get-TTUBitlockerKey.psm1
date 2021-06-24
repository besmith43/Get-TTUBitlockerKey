function Get-TTUBitlockerKey (
    param (
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [string]
        $Hostname,
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Hostnames
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

        $session = New-PSSesion -ComputerName $PassedHostname

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

    # main function
    if ($Hostname -ne $null)
    {
        if (Test-Hostname -Host $Hostname)
        {
            $BitlockerKey = Get-BitlockerKey -PassedHostname $Hostname
            Write-Output $BitlockerKey
        }
    }
    elseif ($Hostnames -ne $null)
    {
        [string[]]$BitlockerKeys

        foreach($hostname in $Hostnames)
        {
            if (Test-Hostname -Host $hostname)
            {
                $BitlockerKey = Get-BitlockerKey -PassedHostname $hostname
                $BitlockerKeys += $BitlockerKey
            }
        }

        Write-Output $BitlockerKeys
    }
    else
    {
        Write-Error "No Parameters were given"
    }
)