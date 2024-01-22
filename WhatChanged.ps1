
# Function to get current record counts of all logs
function Get-LogCounts {
    Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -ne 0 } | 
    Select-Object LogName, RecordCount
}

# Function to get the events between two counts and save them to CSV files
function Get-EventsBetweenCounts($firstCounts, $secondCounts) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    foreach ($log in $secondCounts) {
        $firstCount = $firstCounts | Where-Object { $_.LogName -eq $log.LogName }
        if ($firstCount) {
            $difference = $log.RecordCount - $firstCount.RecordCount
            Write-Host "Number is different -  $difference $($log.RecordCount) minus $($firstCount.RecordCount)"
            if ($difference -gt 0) {
                $events = Get-WinEvent -LogName $log.LogName -MaxEvents $difference | Sort-Object TimeCreated
                Write-Host "$events"
                if ($events) {
                    $safeLogName = $log.LogName -replace "\/", "_"
                    $csvPath = "C:\path\${safeLogName}_NewEvents$timestamp.csv"
                    $events | Select-Object TimeCreated, Id, LevelDisplayName, Message, ProviderName, LogName, TaskDisplayName, MachineName, UserId | Export-Csv -Path $csvPath -NoTypeInformation
                    Write-Host "New events from $($log.LogName) have been saved to $csvPath"
                }
            }
        }
    }
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

# Get the events that occurred between the first and second count and save them to CSV files
Get-EventsBetweenCounts -firstCounts $firstCounts -secondCounts $secondCounts
