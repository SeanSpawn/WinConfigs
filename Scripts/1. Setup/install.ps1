# Define variables
$repo = "fr0st-iwnl/WinConfigs"
$repoUrl = (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest").assets | 
           Where-Object { $_.name -eq "WinConfigs.zip" } | 
           Select-Object -ExpandProperty browser_download_url
$desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
$tempZip = "$env:LOCALAPPDATA\WinConfigs.zip"
$iconUrl = "https://raw.githubusercontent.com/fr0st-iwnl/assets/refs/heads/main/thumbnails/WinConfigs/icon.ico"
$extractedFolder = "$env:LOCALAPPDATA\WinConfigs"  # Extracted folder location in AppData\Local\Temp
$shortcutPath = "$desktopPath\WinConfigs.lnk"  # Shortcut will be on Desktop
$assetsFolder = "$extractedFolder\Assets\Icons"

if (-not (Test-Path -Path $assetsFolder)) {
    Write-Host "Creating Assets folder..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $assetsFolder -Force | Out-Null
}

# Step 1: Download the ZIP file
Write-Host "Downloading the repository..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip

# Step 2: Clean up any existing folder in the Temp directory (Force deletion)
if (Test-Path -Path $extractedFolder) {
    Write-Host "Removing old extracted folder..." -ForegroundColor Yellow
    # Attempt to remove the folder and forcefully remove it
    try {
        # Try deleting the folder
        Remove-Item -Path $extractedFolder -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Host "Could not remove existing folder. Trying again..." -ForegroundColor Red
        # If there was an issue, wait for a few seconds and retry
        Start-Sleep -Seconds 3
        Remove-Item -Path $extractedFolder -Recurse -Force -ErrorAction Stop
    }
}

# Step 3: Create the directory for extraction (will recreate if it was deleted)
Write-Host "Creating directory for extraction..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $extractedFolder -Force | Out-Null

# Step 4: Extract the ZIP file to the specified folder in Temp
Write-Host "Extracting the repository..." -ForegroundColor Cyan
Expand-Archive -Path $tempZip -DestinationPath $extractedFolder -Force

# Step 5: Handle double folder structure (if any)
$innerFolder = Get-ChildItem -Path $extractedFolder -Directory | Select-Object -First 1
if ($innerFolder.Name -match "WinConfigs") {
    Write-Host "Fixing folder structure..." -ForegroundColor Yellow
    Move-Item -Path "$($innerFolder.FullName)\*" -Destination $extractedFolder -Force
    Remove-Item -Path $innerFolder.FullName -Recurse -Force
}

# Step 6: Cleanup the temporary ZIP file
Remove-Item -Path $tempZip -Force

# Step 7: Create Icons folder and download the icon file
Write-Host "Creating Icons folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$extractedFolder\Assets\Icons" -Force | Out-Null

Write-Host "Downloading the icon file..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $iconUrl -OutFile "$extractedFolder\Assets\Icons\icon.ico"

# Step 8: Create the desktop shortcut (will overwrite if exists)
Write-Host "Creating a desktop shortcut..." -ForegroundColor Cyan

# Ensure the Desktop directory exists
if (-not (Test-Path -Path $desktopPath)) {
    Write-Host "Creating the Desktop directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $desktopPath -Force | Out-Null
}

# Create the shortcut using COM object
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)

# Set the target to the folder where the files are extracted
$shortcut.TargetPath = $extractedFolder
$shortcut.WorkingDirectory = $extractedFolder
$shortcut.WindowStyle = 1
$shortcut.IconLocation = "$extractedFolder\Assets\Icons\icon.ico" # Use the downloaded icon from the extracted folder

# Save the shortcut
$shortcut.Save()

# Step 9: Optional: Remove the extracted folder from Temp if no longer needed (comment out if you want to keep)
# Remove-Item -Path $extractedFolder -Recurse -Force

Write-Host "Repository downloaded, extracted to AppData\Local, and shortcut created on Desktop." -ForegroundColor Green
