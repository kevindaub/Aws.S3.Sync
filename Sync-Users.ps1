[CmdletBinding()]
    Param(
        [string]$remote,
        [string]$local,
        [string[]]$users,
        [string]$encryptionKey,
        [string]$logsdir,
        [string]$username,
        [string]$password,
        [switch]$dryrun,
        [switch]$donotexecute,
    )

function Archive-Logs
{
    [CmdletBinding()]
    Param(
        [string]$logsdir
    )

    if (!(Test-Path $logsdir)) {
        New-Item $logsdir -ItemType Directory -Force | Out-Null
    }

    $logs = Get-ChildItem $logsdir -Filter "*.log"
    if ($logs -ne $null) {
        $archivedir = "$logsdir$(Get-Date -format "dd-MM-yyyyTHH.mm.s")"
        Write-Output "Archive Dir $archivedir"
        foreach ($log in $logs) {
            New-Item $archivedir -ItemType Directory -Force | Out-Null
            Move-Item $log.FullName "$archivedir" -Force | Out-Null
        }
    }
}

function Email-Results
{
    [CmdletBinding()]
    Param(
        [string]$smtp = "smtp.gmail.com",
        [int]$smtpport = 587,
        [string]$username,
        [string]$password,
        [string]$subject,
        [string]$body,
        [System.Net.Mail.Attachment[]]$attachments
    )

    $message = New-Object Net.Mail.MailMessage($username, $username, $subject, $body)
    $attachments | ForEach { $message.Attachments.Add($_) }
    $SMTPClient = New-Object Net.Mail.SmtpClient($smtp, $smtpport)
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password);
    $SMTPClient.Send($message)
}

function Sync-Users
{
    [CmdletBinding()]
    Param(
        [string]$remote,
        [string]$local,
        [string[]]$users,
        [string[]]$localdirs = @("Documents", "Desktop")
        [string]$encryptionKey,
        [string]$logsdir,
        [switch]$dryrun
    )

    $start = Get-Date
    Write-Output "Start Sync at $start"

    $dryrunCmd = ""
    if ($dryrun.ToBool()) {
        $dryrunCmd = "--dryrun"
    }

    foreach ($user in $users) {
        $startUser = Get-Date
        Write-Output "Syncing the user of $user at $startUser"
        $command = "aws"

        foreach ($localdir in $localdirs) {
            $args = "s3 sync $local$user\$localdir\ $remote$user/$localdir/ --delete --sse `"aws:kms`" --sse-kms-key-id `"$encryptionKey`" $dryrunCmd"
            Write-Output "$command $args"
			$log = "$logsDir$user-$localdir.log"
            Start-Process $command -ArgumentList $args -NoNewWindow -Wait -RedirectStandardOutput $log
        }

        if (Test-Path $log) {
            Get-Content $log | Write-Output
        } else {
            Write-Warning "This nominally means nothing needed to be synced"
        }

        $stopUser = Get-Date
        Write-Output "Finished syncing the user of $user at $stopUser"
    }

    $stop = Get-Date
    Write-Output "Finished Sync at $stop"
}

if ($donotexecute.ToBool())
{
    $scriptdir = Split-Path $script:MyInvocation.MyCommand.Path
    . "$scriptdir\Sync-Users.ps1"

    Archive-Logs -logsdir $logsdir

    $start = Get-Date

    Sync-Users -remote $remote -local $local -users $users -encryptionKey $encryptionKey -logsdir $logsdir -dryrun:$dryrun

    $logs = Get-ChildItem $logsdir -Filter "*.log"
    $stop = Get-Date
    $attachments = $logs | ForEach { new-object System.Net.Mail.Attachment $_.FullName }
    Email-Results -username $username -password $password -subject "Computer Sync Completed" -body "Computer Sync Completed in '$($stop - $start)' at $stop" -attachments $attachments
}