# List of target computers
$computers = @("T1-WIN10-1", "T1-WIN10-2", "T1-WIN10-3", "T1-WIN10-4", "T1-WIN10-5")

# Local path to the source files (from file share to admin's machine beforehand)
$sourcePath = "\\file\RANGE"  # Or download these to local disk first
$localTempPath = "$env:TEMP\AgentDeploy"

# Destination on remote machines
$remoteDest = "C:\Users\Public"

# List of files to deploy
$fileNames = @("elastic_agent.exe", "Sysmon64.exe", "sysmonconfig.xml")

# Prompt for domain credentials (used for remote session, not file share)
$cred = Get-Credential -Message "Enter domain credentials for remote connection"

# Create temp folder on admin machine if needed
if (-not (Test-Path $localTempPath)) {
    New-Item -Path $localTempPath -ItemType Directory -Force | Out-Null
}

# Copy files from share to local admin machine once
foreach ($file in $fileNames) {
    $sourceFile = Join-Path -Path $sourcePath -ChildPath $file
    $destFile = Join-Path -Path $localTempPath -ChildPath $file
    Copy-Item -Path $sourceFile -Destination $destFile -Force
}

# Main loop for each remote computer
foreach ($computer in $computers) {
    Write-Host "`nConnecting to $computer..." -ForegroundColor Cyan

    try {
        $session = New-PSSession -ComputerName $computer -Credential $cred

        # Copy files to remote machine
        foreach ($file in $fileNames) {
            $localFile = Join-Path $localTempPath $file
            $remoteFile = Join-Path $remoteDest $file
            Copy-Item -Path $localFile -Destination $remoteFile -ToSession $session -Force
        }

        # Run remote setup commands
        Invoke-Command -Session $session -ScriptBlock {
            $dest = "C:\Users\Public"
            Set-Location $dest

            Write-Host "Installing Sysmon..." -ForegroundColor Yellow
            .\Sysmon64.exe -accepteula -i sysmonconfig.xml

            Write-Host "Starting Elastic Agent..." -ForegroundColor Yellow
            Start-Process "$dest\elastic_agent.exe" -ArgumentList "-install" -Wait

            # Check service status
            $services = @("Sysmon64", "Elastic Agent")

            foreach ($svc in $services) {
                $status = Get-Service -Name $svc -ErrorAction SilentlyContinue
                if ($status.Status -eq 'Running') {
                    Write-Host "$svc is running." -ForegroundColor Green
                } else {
                    Write-Host "$svc is NOT running." -ForegroundColor Red
                }
            }
        }

        Remove-PSSession $session
        Write-Host "Finished with $computer." -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error connecting to $computer" -ForegroundColor Red
    }
}
