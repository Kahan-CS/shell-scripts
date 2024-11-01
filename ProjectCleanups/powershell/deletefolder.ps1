# Two parameters are required: targetFolder and folderName, which are the directory path and the folder name to be deleted, respectively.

# This script will delete all folders with the specified name within the target directory and its subdirectories.

# Parameters
param (
    [switch]$Help,  # Add a parameter to show help

    [string]$targetFolder,
    
    [string]$folderName,   # Specify the folder name to be deleted

    [switch]$LogToFile,  # Add a switch for logging

    [switch]$CustomVerbose,  # Add a switch for verbose mode

    [switch]$NoZip,        # Add a switch to skip deletion inside zip files

    [string[]]$ExcludePaths  # Add an array of paths or folder names to exclude from deletion

)

# Show Helo Menu
function Show-Help {
    Write-Host "Shell Script: *DeleteFolder* Help Menu" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host "Pre-requisites: PowerShell 5.1 or later" -ForegroundColor Yellow
    Write-Host "Usage: C:\path\to\script\name_of_script.ps1 -targetFolder 'C:\path\to\your\folder' -folderName 'name_of_folder' [-LogToFile] [-CustomVerbose] [-NoZip] [-ExcludePaths 'C:\path\to\exclude']" -ForegroundColor White
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow

    Write-Host -NoNewline "  -targetFolder  : " -ForegroundColor White
    Write-Host -NoNewLine "(MANDATORY)" -ForegroundColor Red
    Write-Host "The directory path where the script will look for folders to delete." -ForegroundColor Yellow
    Write-Host -NoNewline "  -folderName    : " -ForegroundColor White
    Write-Host -NoNewLine "(MANDATORY)" -ForegroundColor Red
    Write-Host "The name of the folder(s) to be deleted within the target directory. " -ForegroundColor Yellow
    Write-Host "" # New line
    Write-Host -NoNewline "  -LogToFile     : " -ForegroundColor White
    Write-Host "(Optional) Enable logging to a file in the target directory." -ForegroundColor Yellow
    Write-Host -NoNewline "  -CustomVerbose       : " -ForegroundColor White
    Write-Host "(Optional) Show detailed processing information." -ForegroundColor Yellow
    Write-Host -NoNewline "  -NoZip         : " -ForegroundColor White
    Write-Host "(Optional) Skip deletion of specified folders inside zip files." -ForegroundColor Yellow
    Write-Host -NoNewline "  -ExcludePaths  : " -ForegroundColor White
    Write-Host "(Optional) Specify paths (OR Folders) to exclude from deletion. Can be an array of paths, but can also include specific Folders." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  1. To delete a folder: .\name_of_script.ps1 -targetFolder 'C:\example' -folderName 'temp'" 
    Write-Host "  2. To log to a file: .\name_of_script.ps1 -targetFolder 'C:\example' -folderName 'temp' -LogToFile" 
    Write-Host "  3. To enable verbose output: .\name_of_script.ps1 -targetFolder 'C:\example' -folderName 'temp' -CustomVerbose" 
    Write-Host "  4. To skip zip files: .\name_of_script.ps1 -targetFolder 'C:\example' -folderName 'temp' -NoZip" 
    Write-Host "  5. To exclude specific paths: .\name_of_script.ps1 -targetFolder 'C:\example' -folderName 'temp' -ExcludePaths 'C:\exclude_this'" 
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For more information, contact the script author: Kahan Desai" 
    Write-Host "GitHub: https://github.com/kahan-cs/shell-scripts" 
}

# Check for help request
if ($Help) {
    Show-Help
    exit
}


# Check for mandatory parameters
if (-not $PSCmdlet -or -not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('targetFolder') -or 
    -not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('folderName')) {
    Write-Output "Error: Missing mandatory parameters."
    Write-Output "Use -Help to see the list of available commands and their usage."
    exit 1
}

# Validate that the target folder exists
if (-not [string]::IsNullOrWhiteSpace($targetFolder) -and -not (Test-Path -Path $targetFolder)) {
    Write-Output "Error: The specified folder path does not exist: $targetFolder"
    exit 1
}

# Check for invalid parameters
$validParams = @("targetFolder", "folderName", "LogToFile", "CustomVerbose", "NoZip", "ExcludePaths", "Help")
$providedParams = $PSCmdlet.MyInvocation.BoundParameters.Keys

foreach ($param in $providedParams) {
    if ($validParams -notcontains $param) {
        Write-Output "Error: Invalid parameter -$param."
        Write-Output "Use -Help to see the list of available commands and their usage."
        exit 1
    }
}

# Prepare excluded paths based on ExcludePaths input
$excludedPaths = @()

foreach ($exclude in $ExcludePaths) {
    if (Test-Path -Path $exclude) {
        # It's a valid path, add to excluded paths
        $excludedPaths += $exclude
    } else {
        # Assume it's a folder name, search for it
        $matchingFolders = Get-ChildItem -Path $targetFolder -Recurse -Force -Directory | Where-Object { $_.Name -eq $exclude }
        $excludedPaths += $matchingFolders.FullName
    }
}


# Define the log file path if logging is enabled
if ($LogToFile) {
    $logFilePath = Join-Path -Path $targetFolder -ChildPath "deletion_log.txt"
    Add-Content -Path $logFilePath -Value "$(Get-Date): Starting deletion process for '$folderName' folders in $targetFolder."
}

# Function Definitions
# =====================



# Function to handle both verbose output and logging
function Write-Message {
    param (
        [string]$message,
        [switch]$isVerbose = $false
    )
    if ($isVerbose -and $CustomVerbose) {
        Write-Output "VERBOSE: $message"
    }
    if ($LogToFile) {
        Add-Content -Path $logFilePath -Value "$message"
    }
}

# Function to remove specified folders within a given directory path
function Remove-TargetFoldersInDirectory {
    param ([string]$path, [string]$folderName)
    
    $folders = Get-ChildItem -Path $path -Recurse -Force -Directory -Filter $folderName
    $folderCount = $folders.Count
    $i = 0

    foreach ($folder in $folders) {
        # Check if the folder is in the excluded paths
        if ($excludedPaths -contains $folder.FullName) {
            Write-Output "Skipping excluded folder: $($folder.FullName)"
            Write-Message "Skipping excluded folder: $($folder.FullName)"
            continue  # Skip the iteration
        }

        Write-Message "Found $folderCount '$folderName' folders to delete in $path" -isVerbose $true
        $i++
        Write-Progress -Activity "Deleting '$folderName' folders in directories" -Status "Processing folder $i of $folderCount" -PercentComplete (($i / $folderCount) * 100)
        try {
            $folder | Get-ChildItem -Recurse -Force | ForEach-Object { $_.Attributes = 'Normal' }
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
            Write-Output "Deleted: $($folder.FullName)"
            Write-Message "Deleted: $($folder.FullName)"
        }
        catch {
            Write-Output "Failed to delete: $($folder.FullName) - $_"
            Write-Message "Failed to delete: $($folder.FullName) - $_"
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

        # Check if the zip file is in the excluded paths
        if ($ExcludePaths -contains $zipFile.FullName) {
            Write-Output "Skipping excluded zip file: $($zipFile.FullName)"
            Write-Message "Skipping excluded zip file: $($zipFile.FullName)"
            continue  # Skip this iteration
        }

        $j++
        Write-Progress -Activity "Processing .zip files" -Status "Processing zip file $j of $zipCount" -PercentComplete (($j / $zipCount) * 100)
        $zipPath = $zipFile.FullName
        Write-Message "Processing zip file: $zipPath" -isVerbose $true
        $tempExtractPath = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension($zipPath))

        try {
            # Extract the zip file to a temporary location
            Write-Output "Extracting $zipPath to $tempExtractPath"
            Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
            Write-Message "Expanded zip file to temporary path: $tempExtractPath" -isVerbose $true

            # Remove specified folders from the extracted content
            Remove-TargetFoldersInDirectory -path $tempExtractPath -folderName $folderName

            # Recreate the zip file without the specified folders
            Write-Output "Recompressing $zipPath without '$folderName' folders"
            Compress-Archive -Path "$tempExtractPath\*" -DestinationPath $zipPath -Force
            Write-Message "Recompressed $zipPath without '$folderName' folders" -isVerbose $true

            # Clean up the temporary extraction path
            Remove-Item -Path $tempExtractPath -Recurse -Force
        }
        catch {
            Write-Output "Error processing zip file: $zipPath - $_"
            Write-Message "Error processing zip file: $zipPath - $_"
        }
    }
    Write-Output "All '$folderName' folders inside zip files have been deleted."
    Write-Message "All '$folderName' folders inside zip files have been deleted."
}


# Main Script Execution
# =====================

# Check if the specified folder exists
if (Test-Path -Path $targetFolder) {
    # Confirmation prompt
    $confirmation = Read-Host -Prompt "CAUTION! Are you sure you want to delete all '$folderName' folders in $targetFolder? Type 'Yes' to confirm"
    if ($confirmation -ne "Yes") {
        Write-Output "Operation cancelled."
        exit
    }
    # Delete all specified folders in the directory and subdirectories
    Write-Message "Starting deletion of '$folderName' folders in $targetFolder" -isVerbose $true
    Remove-TargetFoldersInDirectory -path $targetFolder -folderName $folderName

    # Second confirmation prompt for zip files
    if (-not $NoZip) 
    {
        $zipConfirmation = Read-Host -Prompt "Do you also want to delete '$folderName' folders inside zip files? Type 'Yes' to confirm"
        if ($zipConfirmation -eq "Yes") {
            Write-Message "Starting deletion of '$folderName' folders within zip files in $targetFolder" -isVerbose $true
            Remove-TargetFoldersInZipFiles -path $targetFolder -folderName $folderName
        } else {
            Write-Output "Skipping deletion inside zip files."
            Write-Message "Skipping deletion inside zip files."
        }
    } else {
        Write-Output "Skipping deletion inside zip files as per user request."
        Write-Message "Skipping deletion inside zip files as per user request."
    }

    if ($LogToFile) {
        Add-Content -Path $logFilePath -Value "$(Get-Date): Deletion process completed."
    }
    Write-Message "Deletion process completed for all specified folders." -isVerbose $true
} else {
    Write-Output "The specified folder path does not exist: $targetFolder"
    Write-Message "The specified folder path does not exist: $targetFolder"
}
