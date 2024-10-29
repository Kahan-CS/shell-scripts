param (
    [Parameter(Mandatory = $true)]
    [string]$targetFolder
)

# Confirmation prompt
$confirmation = Read-Host -Prompt "CAUTION! Are you sure you want to delete all 'x64' folders in $targetFolder? Type 'Yes' to confirm"

if ($confirmation -ne "Yes") {
    Write-Output "Operation cancelled."
    exit
}

# Function to remove x64 folders within a given directory path
function Remove-X64FoldersInDirectory {
    param ([string]$path)
    
    Get-ChildItem -Path $path -Recurse -Force -Directory -Filter "x64" | ForEach-Object {
        try {
            $_ | Get-ChildItem -Recurse -Force | ForEach-Object { $_.Attributes = 'Normal' }
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
            Write-Output "Deleted: $($_.FullName)"
        }
        catch {
            Write-Output "Failed to delete: $($_.FullName) - $_"
        }
    }
}

# Check if the specified folder exists
if (Test-Path -Path $targetFolder) {
    # Delete all x64 folders in the directory and subdirectories
    Remove-X64FoldersInDirectory -path $targetFolder
    Write-Output "All x64 folders have been deleted from $targetFolder"
} else {
    Write-Output "The specified folder path does not exist: $targetFolder"
}
