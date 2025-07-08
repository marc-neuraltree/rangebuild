# Create the main folder
$mainFolder = "C:\Beleng Shared Drive"
New-Item -Path $mainFolder -ItemType Directory -Force

# Share the folder with Domain Users. Change domain number with team number
$shareName = "Beleng Shared Drive"
New-SmbShare -Name $shareName -Path $mainFolder -FullAccess "beleng#\Domain Users"

# List of department folders
$departments = @("Finance", "IT", "Missions", "Plans", "Engineering", "HR")

# Create department folders inside "Beleng Share"
foreach ($dept in $departments) {
    New-Item -Path "C:\Beleng Shared drive\$dept" -ItemType Directory -Force
}

# Define a hashtable where keys are department names and values are arrays of subfolder names
$departmentSubfolders = @{
    "Finance"     = @("Budgets", "Invoices", "Audits")
    "IT"          = @("Infrastructure", "Support", "Backups")
    "Missions"    = @("Past Missions", "Reports", "Ongoing Missions")
    "Plans"       = @("Strategies", "Schedules", "Reviews")
    "Engineering" = @("Designs", "Blueprints", "Prototypes")
    "HR"          = @("Recruitment", "EmployeeRecords", "Policies")
}
$rootPath = "C:\Beleng Shared Drive"

# Loop through the hashtable and create each folder and its subfolders
foreach ($dept in $departmentSubfolders.Keys) {
    $deptPath = Join-Path -Path $rootPath -ChildPath $dept

    # Loop through each and create subfolders
    foreach ($sub in $departmentSubfolders[$dept]) {
        $path = Join-Path -Path $deptPath -ChildPath $sub
        New-Item -Path $path -ItemType Directory -Force
    }
}
