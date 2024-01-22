# Function to get current record counts of all logs
function Get-LogCounts {
    Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -ne 0 } | 
    Select-Object LogName, RecordCount
}

Write-Host "Capturing initial event log counts..."
# Capture the first set of record counts
$firstCounts = Get-LogCounts

# Wait for user input - Press 'P' to proceed
Write-Host "Press 'P' to capture the next set of event log counts..."
$startTime = Get-Date
do {
    $input = [console]::ReadKey($true)
    $currentTime = Get-Date
    $elapsedSeconds = ($currentTime - $startTime).TotalSeconds
} while ($input.Key -ne "P")


# Capture the second set of record counts
Write-Host "Capturing event log counts after $elapsedSeconds seconds..."
$secondCounts = Get-LogCounts

# Compare the counts and identify logs with increased record numbers
Write-Host "Comparing event log counts..."
$logsIncreased = Compare-Object -ReferenceObject $firstCounts -DifferenceObject $secondCounts `
                 -Property LogName, RecordCount | 
                 Where-Object { $_.SideIndicator -eq "=>" }

# Extract events from the logs that have increased and save to CSV
foreach ($log in $logsIncreased) {
    $logName = $log.LogName
    $oldCount = ($firstCounts | Where-Object { $_.LogName -eq $logName }).RecordCount
    Write-Host "Checking new events for $logName..."
    $newEvents = Get-WinEvent -LogName $logName | 
                 Where-Object { $_.RecordId -gt $oldCount }

    $newEventCount = $newEvents.Count
    Write-Host "Found $newEventCount new events in $logName."

    # Replace backslashes in the log name with underscores for the filename
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $safeLogName = $logName -replace "\/", "_"
    $csvPath = "C:\path\${safeLogName}_NewEvents$timestamp.csv"

    $newEvents | Select-Object TimeCreated, Id, LevelDisplayName, Message, ProviderName, LogName, TaskDisplayName, MachineName, UserId | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "New events from $logName have been saved to $csvPath"
}

Write-Host "Script execution completed."
