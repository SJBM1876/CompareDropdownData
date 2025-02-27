# Set file path for CSV
$csvPath = "C:\Users\Laptop\Documents\WindowsPowerShell\CompareDropdownData\CarBrands.csv"

# Set website URL with dropdown
$websiteUrl = "https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_select"

# Function to Read CSV File (with UTF-8 encoding)
function Read-CountryCSV {
    param ([string]$filePath)

    if (-Not (Test-Path $filePath)) {
        Write-Host "Error: CSV file not found at $filePath" -ForegroundColor Red
        return @()
    }

    # Read CSV file with UTF-8 encoding to prevent character corruption
    $csvData = Get-Content -Path $filePath -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    return $csvData
}

# Function to Scrape Dropdown Menu Items
function Scrape-DropdownOptions {
    param ([string]$url)

    # Get webpage HTML
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    $html = $response.Content

    # Extract dropdown options using regex
    $matches = [regex]::Matches($html, "<option.*?>(.*?)</option>")

    # Extract option values and decode HTML entities
    $dropdownList = @()
    foreach ($match in $matches) {
        $optionText = $match.Groups[1].Value.Trim()

        # Decode HTML entities using System.Net.WebUtility
        $decodedOption = [System.Net.WebUtility]::HtmlDecode($optionText)

        $dropdownList += $decodedOption
    }

    return $dropdownList
}

# Read CSV & Scrape Dropdown Menu Data
$csvData = Read-CountryCSV -filePath $csvPath
$dropdownData = Scrape-DropdownOptions -url $websiteUrl

Write-Host "`nCSV Data ($($csvData.Count) items):" -ForegroundColor Cyan
$csvData | ForEach-Object { Write-Host $_ }

Write-Host "`nDropdown Data ($($dropdownData.Count) items):" -ForegroundColor Green
$dropdownData | ForEach-Object { Write-Host $_ }

# Compare CSV vs Dropdown
Write-Host "`nComparing Data..." -ForegroundColor Yellow

# Find missing options
$missingOnWebsite = $csvData | Where-Object { $_ -notin $dropdownData }
$missingInCSV = $dropdownData | Where-Object { $_ -notin $csvData }

# Display Differences
if ($missingOnWebsite.Count -gt 0 -or $missingInCSV.Count -gt 0) {
    Write-Host "`nDifferences found:" -ForegroundColor Red

    if ($missingOnWebsite.Count -gt 0) {
        Write-Host "In CSV but missing from Website:" -ForegroundColor Magenta
        $missingOnWebsite | ForEach-Object { Write-Host $_ }
    }

    if ($missingInCSV.Count -gt 0) {
        Write-Host "On Website but missing from CSV:" -ForegroundColor Magenta
        $missingInCSV | ForEach-Object { Write-Host $_ }
    }
} else {
    Write-Host "`nBoth lists match!" -ForegroundColor Green
}
