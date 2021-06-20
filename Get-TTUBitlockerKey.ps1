param (
    [string]$SavePath = $PSScriptRoot,
    [switch]$Debug
)

if ($Debug)
{
    $content = get-content .\example.txt
}
else
{
    $content = $(manage-bde C: -protectors -get -type RecoveryPassword)
}

$password = $content[9]

$password = $password.Trim()

$hostname = hostname

set-content -Path "$SavePath\$hostname.txt" -Value $password

