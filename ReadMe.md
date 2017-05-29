# Aws.S3.Sync

Small wrapper script that calls AWS S3 synchronization and emails the results at the end.

## TODO

- [ ] Store encryption key securely.
- [ ] Store email password securely.
- [ ] Sign script
- [ ] Create chocolatey package.

## Preqs

- [AWS PowerShell Tools](http://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up.html)

## Usage

```powershell
$remote = "s3://bucketname/"
$local = "C:\users\"
$users = @("User1","User2")
$encryptionKey = "0000000-0000-0000-0000-000000000000"
$username = "me@kevindaub.com"
$password = "a_secret"
$logsdir = "C:\sync\logs\"
$dryrun = $false

$scriptdir = Split-Path $script:MyInvocation.MyCommand.Path
. "$scriptdir\SyncUsers.ps1" -remote $remote -local $local -users $users -encryptionKey $encryptionKey -logsdir $logsdir -username $username -password $password -dryrun:$dryrun
```

```dos
powershell.exe -executionpolicy bypass C:\example_above.ps1
```
