param (
    [Parameter(Mandatory = $true)]
    [string]$targetFolder
)

# Check if the specified folder exists
if (Test-Path -Path $targetFolder) {
    # Get all .vs folders recursively, including hidden ones
    Get-ChildItem -Path $targetFolder -Recurse -Force -Directory -Filter ".vs" | ForEach-Object {
        try {
            # Remove hidden and read-only attributes from the folder and its contents
            $_ | Get-ChildItem -Recurse -Force | ForEach-Object { 
                $_.Attributes = 'Normal'
            }
            
            # Now delete the .vs folder and its contents
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
            Write-Output "Deleted: $($_.FullName)"
        }
        catch {
            Write-Output "Failed to delete: $($_.FullName) - $_"
        }
    }

    Write-Output "All .vs folders have been deleted from $targetFolder."
} else {
    Write-Output "The specified folder path does not exist: $targetFolder"
}
