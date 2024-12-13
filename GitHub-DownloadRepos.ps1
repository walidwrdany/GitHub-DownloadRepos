
# Function to run a batch file
function Run-BatchFile {
    param (
        [string]$FileName
    )
    $fullPath = Join-Path -Path (Get-Location) -ChildPath $FileName
    if (Test-Path -Path $fullPath) {
        Start-Process cmd.exe -ArgumentList "/c `"$fullPath`"" -Wait
    } else {
        Write-Error "Batch file '$FileName' not found in the current directory."
        exit 1
    }
}

# Ensure GitHub CLI (gh) is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI is not installed. Installing dependencies..."

    # Run InstallChocolatey.bat
    Run-BatchFile "InstallChocolatey.bat"

    # Run GitHubCLI-install.bat
    Run-BatchFile "GitHubCLI-install.bat"

    # Re-check for GitHub CLI
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Error "GitHub CLI installation failed."
        exit 1
    }
}

# Define the download directory (change this to your desired location)
$downloadDir = Join-Path -Path (Get-Location) -ChildPath "GitHubRepositories"

# Create the directory if it doesn't exist
if (-not (Test-Path -Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
}

# Fetch all repositories with ownership and visibility details
Write-Host "Fetching repositories..."
$repositories = gh repo list --source --json nameWithOwner,isFork,visibility --limit 1000 | ConvertFrom-Json

# Process each repository
foreach ($repo in $repositories) {
    $nameWithOwner = $repo.NameWithOwner
    $isFork        = $repo.IsFork -eq "true"
    $visibility    = $repo.Visibility.ToLower()  # Convert visibility to lowercase

    # Determine ownership type and folder name
    $repoType = if ($isFork) { "Forked" } else { "Owned" }
    $folder = "${repoType}_${visibility}"

    # Extract repository name from 'NameWithOwner'
    $repoName = ($nameWithOwner -split "/")[1]
	
    # Skip specific repository
    if ($repoName -eq "GitHub-DownloadRepos") {
        Write-Host "Skipping repository: $repoName"
        continue
    }

    # Create folder structure
    $repoPath = Join-Path -Path $downloadDir -ChildPath $folder
    if (-not (Test-Path -Path $repoPath)) {
        New-Item -ItemType Directory -Path $repoPath | Out-Null
    }
	
    $repoClonePath = Join-Path -Path $repoPath -ChildPath $repoName

    Write-Host "Cloning repository: $nameWithOwner to $repoClonePath"

    # Clone the repository
    gh repo clone $nameWithOwner $repoClonePath
}

Write-Host ""
Write-Host "All repositories have been downloaded to $downloadDir."
Write-Host "Sync scripts have been created for each repository."
Pause
