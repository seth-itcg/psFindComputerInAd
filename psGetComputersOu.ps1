# It's best if this script is run on a domain controller. 
# At least it has to have the Active Directory module installed.
# This script prompts the user for a computer name and retrieves 
# its Organizational Unit (OU) or container from Active Directory.


clear-host
# Load Active Directory module
Import-Module ActiveDirectory

# Get the domain the local computer is joined to.
$domain = (Get-ADDomain).DNSRoot

# Find domain controller, prompt user to input one or press Enter to to use the default.
$defaultDC = (Get-ADDomainController -Discover -Service "PrimaryDC").HostName | Out-String | ForEach-Object { $_.Trim() }
$dcInput = Read-Host "Enter a Domain Controller to use or press Enter to use the default ($defaultDC)"
if ([string]::IsNullOrWhiteSpace($dcInput)) {
    $domainController = $defaultDC
} else {
    $domainController = $dcInput
}
Write-Host "Using Domain Controller: $domainController"
# Prompt user for a computer name.
$computerName = Read-Host "Enter the computer name to find its OU"
# Search for the computer in Active Directory.
try {
    Write-Host "Searching for computer '$computerName' on $domainController..."
    $computer = Get-ADComputer -Identity $computerName -Server $domainController -ErrorAction Stop
    # Output the OU or container of the computer.
    $location = $computer.DistinguishedName -replace '^CN=[^,]+,', ''
    
    Write-Host "`n  - $($computer.Name)" -ForegroundColor Cyan
    Write-Host "      $location" -ForegroundColor Gray
} catch {
    Write-Host "`nError: Could not find computer '$computerName' in the domain '$domain'."
    Write-Host "`nSearching for similar computer names..."
    
    # Try to find similar computer names
    try {
        $similarComputers = Get-ADComputer -Filter "Name -like '*$computerName*'" -Server $domainController -Properties DistinguishedName | Select-Object -First 10
        if ($similarComputers) {
            Write-Host "`nFound similar computers:"
            $similarComputers | ForEach-Object {
                Write-Host "  - $($_.Name)" -ForegroundColor Cyan
                $location = $_.DistinguishedName -replace '^CN=[^,]+,', ''
                Write-Host "      $location" -ForegroundColor Gray
            }
        } else {
            Write-Host "No similar computer names found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Unable to search for similar computers. Error: $_" -ForegroundColor Red
    }
}
Write-Host "`n"
# End of script