# List of target computers
$computers = @("T1-WIN10-01", "T1-WIN10-2", "T1-WIN10-3", "T1-WIN10-4", "T1-WIN10-5")

# Source file share and file names
$sourcePath = "\\file\RANGE"
$fileNames = @("elastic_agent.exe", "Sysmon64.exe", "sysmonconfig.xml")
$destinationPath = "C:\Users\Public"

# Domain credentials (prompt)
$cred = Get-Credential -Message "Enter DOMAIN credentials to access file share and remote systems"

# Loop through each computer
foreach ($computer in $computers) {
    Write-Host "`nConnecting to $computer..." -ForegroundColor Cyan

    Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
        param ($src, $files, $dest)

        # Ensure destination folder exists
        if (-not (Test-Path $dest)) {
            New-Item -Path $dest -ItemType Directory -Force
        }

        # Copy files from share to local
        foreach ($file in $files) {
            $sourceFile = Join-Path -Path $src -ChildPath $file
            $destFile = Join-Path -Path $dest -ChildPath $file
            Copy-Item -Path $sourceFile -Destination $destFile -Force
        }

        # Change to destination directory
        Set-Location $dest

        # Run Sysmon
        Write-Host "Installing Sysmon..." -ForegroundColor Yellow
        .\Sysmon64.exe -i -accepteula -c sysmonconfig.xml

        # Run Elastic Agent (this assumes silent install or self-starting agent)
        Write-Host "Starting Elastic Agent..." -ForegroundColor Yellow
        Start-Process "$dest\elastic_agent.exe" -ArgumentList "-install" -Wait

        # Validate services are running
        $services = @("Sysmon64", "Elastic Agent")

        foreach ($svc in $services) {
            $status = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($status.Status -eq 'Running') {
                Write-Host "$svc is running." -ForegroundColor Green
            } else {
                Write-Host "$svc is NOT running." -ForegroundColor Red
            }
        }

    } -ArgumentList $sourcePath, $fileNames, $destinationPath -ErrorAction Stop

    Write-Host "Finished with $computer." -ForegroundColor Cyan
}
