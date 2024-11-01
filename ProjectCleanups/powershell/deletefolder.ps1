# Two parameters are required: targetFolder and folderName, which are the directory path and the folder name to be deleted, respectively.

# This script will delete all folders with the specified name within the target directory and its subdirectories.


param (
    [Parameter(Mandatory = $true)]
    [string]$targetFolder,
    
    [Parameter(Mandatory = $true)]
    [string]$folderName
)

# Confirmation prompt
$confirmation = Read-Host -Prompt "CAUTION! Are you sure you want to delete all '$folderName' folders in $targetFolder? Type 'Yes' to confirm"
if ($confirmation -ne "Yes") {
    Write-Output "Operation cancelled."
    exit
}

# Function to remove specified folders within a given directory path
function Remove-TargetFoldersInDirectory {
    param ([string]$path, [string]$folderName)
    
    $folders = Get-ChildItem -Path $path -Recurse -Force -Directory -Filter $folderName
    $folderCount = $folders.Count
    $i = 0

    foreach ($folder in $folders) {
        $i++
        Write-Progress -Activity "Deleting '$folderName' folders in directories" -Status "Processing folder $i of $folderCount" -PercentComplete (($i / $folderCount) * 100)
        try {
            $folder | Get-ChildItem -Recurse -Force | ForEach-Object { $_.Attributes = 'Normal' }
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
            Write-Output "Deleted: $($folder.FullName)"
        }
        catch {
            Write-Output "Failed to delete: $($folder.FullName) - $_"
        }
    }
}

# Function to process specified folders inside zip files
function Remove-TargetFoldersInZipFiles {
    param ([string]$path, [string]$folderName)
    
    $zipFiles = Get-ChildItem -Path $path -Recurse -Force -Filter "*.zip"
    $zipCount = $zipFiles.Count
    $j = 0

    foreach ($zipFile in $zipFiles) {
        $j++
        Write-Progress -Activity "Processing .zip files" -Status "Processing zip file $j of $zipCount" -PercentComplete (($j / $zipCount) * 100)
        $zipPath = $zipFile.FullName
        $tempExtractPath = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension($zipPath))

        try {
            # Extract the zip file to a temporary location
            Write-Output "Extracting $zipPath to $tempExtractPath"
            Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force

            # Remove specified folders from the extracted content
            Remove-TargetFoldersInDirectory -path $tempExtractPath -folderName $folderName

            # Recreate the zip file without the specified folders
            Write-Output "Recompressing $zipPath without '$folderName' folders"
            Compress-Archive -Path "$tempExtractPath\*" -DestinationPath $zipPath -Force

            # Clean up the temporary extraction path
            Remove-Item -Path $tempExtractPath -Recurse -Force
        }
        catch {
            Write-Output "Error processing zip file: $zipPath - $_"
        }
    }
    Write-Output "All '$folderName' folders inside zip files have been deleted."
}

# Check if the specified folder exists
if (Test-Path -Path $targetFolder) {
    # Delete all specified folders in the directory and subdirectories
    Remove-TargetFoldersInDirectory -path $targetFolder -folderName $folderName

    # Second confirmation prompt for zip files
    $zipConfirmation = Read-Host -Prompt "Do you also want to delete '$folderName' folders inside zip files? Type 'Yes' to confirm"
    if ($zipConfirmation -eq "Yes") {
        Remove-TargetFoldersInZipFiles -path $targetFolder -folderName $folderName
    } else {
        Write-Output "Skipping deletion inside zip files."
    }
} else {
    Write-Output "The specified folder path does not exist: $targetFolder"
}