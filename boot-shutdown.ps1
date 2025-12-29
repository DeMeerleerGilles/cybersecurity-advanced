# PowerShell script to manage CSA lab VMs with VBoxManage

# List of VMs
$VMs = @(
    "companyrouter 1",
    "dns",
    #"web",
    "database",
    "employee",
    "isprouter",
    "homerouter",
    "remote-employee",
    #"red-kali",
    "siem"
)

function Start-CSA-Machines {
    Write-Host "Starting CSA lab machines..."
    foreach ($vm in $VMs) {
        Write-Host "Starting $vm ..."
        VBoxManage startvm $vm --type headless
    }
}

function Stop-CSA-Machines {
    Write-Host "Stopping CSA lab machines..."
    foreach ($vm in $VMs) {
        Write-Host "Stopping $vm ..."
        VBoxManage controlvm $vm acpipowerbutton
    }
    Write-Host "All stop signals sent (ACPI shutdown)."
}


function Manage-CSA-Lab {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("start","stop","restart")]
        [string]$Action
    )

    switch ($Action) {
        "start"   { Start-CSA-Machines }
        "stop"    { Stop-CSA-Machines }
        "restart" {
            Stop-CSA-Machines
            Start-Sleep -Seconds 10
            Start-CSA-Machines
        }
    }
}

# Main script
$action = Read-Host "Enter action (start, stop, restart)"
Manage-CSA-Lab -Action $action
Write-Host "Operation '$action' completed."
