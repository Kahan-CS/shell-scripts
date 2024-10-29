param (
    [Parameter(Mandatory = $true)]
    [string]$targetFolder
)

# Confirmation prompt
$confirmation = Read-Host -Prompt "CAUTION! Are you sure you want to delete all '.vs' folders in $targetFolder? Type 'Yes' to confirm"

if ($confirmation -ne "Yes") {
    Write-Output "Operation cancelled."
    exit
}

# Function to remove .vs folders within a given directory path
function Remove-VsFoldersInDirectory {
    param ([string]$path)
    
    Get-ChildItem -Path $path -Recurse -Force -Directory -Filter ".vs" | ForEach-Object {
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
    # Delete all normal .vs folders in the directory and subdirectories
    Remove-VsFoldersInDirectory -path $targetFolder

    # Second confirmation prompt for zip files
    $zipConfirmation = Read-Host -Prompt "Do you also want to delete '.vs' folders inside zip files? Type 'Yes' to confirm"
    if ($zipConfirmation -ne "Yes") {
        Write-Output "Skipping deletion inside zip files."
    } else {

        # Find all zip files in the directory and subdirectories
        Get-ChildItem -Path $targetFolder -Recurse -Force -Filter "*.zip" | ForEach-Object {
            $zipPath = $_.FullName
            $tempExtractPath = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension($zipPath))

            try {
                # Extract the zip file to a temporary location
                Write-Output "Extracting $zipPath to $tempExtractPath"
                Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force

                # Remove .vs folders from the extracted content
                Remove-VsFoldersInDirectory -path $tempExtractPath

                # Recreate the zip file without the .vs folders
                Write-Output "Recompressing $zipPath without .vs folders"
                Compress-Archive -Path "$tempExtractPath\*" -DestinationPath $zipPath -Force

                # Clean up the temporary extraction path
                Remove-Item -Path $tempExtractPath -Recurse -Force
            }
            catch {
                Write-Output "Error processing zip file: $zipPath - $_"
            }
        }
    }

    Write-Output "All .vs folders have been deleted from $targetFolder and inside zip files."
} else {
    Write-Output "The specified folder path does not exist: $targetFolder"
}
