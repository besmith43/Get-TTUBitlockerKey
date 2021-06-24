param (
    [string]$SavePath = $PSScriptRoot,
    [switch]$ScheduledTask,
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

if ($ScheduledTask)
{
    set-content -Path "C:\Users\besmith\OneDrive - Tennessee Tech University\Bitlocker Key\$hostname.txt" -Value $password -Force
}
else
{
    set-content -Path "$SavePath\$hostname.txt" -Value $password -Force
}
