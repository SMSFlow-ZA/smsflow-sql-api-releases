param(
    [string]$Version = '0.3.0',
    [string]$AssetDirectory = 'artifacts/smoke/v0.3.0'
)

$ErrorActionPreference = 'Stop'

$releaseName = "smsflow-sql-api-$Version"
$requiredAssets = @(
    "$releaseName-windows-host.zip",
    "$releaseName-windows-manager.zip",
    "$releaseName-linux-host.zip",
    "$releaseName-docker-host.zip",
    'CHECKSUMS-SHA256.txt'
)

$requiredZipEntries = @{
    "$releaseName-windows-host.zip" = @(
        'Install-SMSFlowSqlIntegrationHost.ps1',
        'InstallerWizard',
        'FirstRunValidator',
        'SchemaMigrator',
        'sql_integration_v2.sql'
    )
    "$releaseName-windows-manager.zip" = @(
        'Install-SMSFlowSqlIntegrationManager.ps1',
        'Management'
    )
    "$releaseName-linux-host.zip" = @(
        'Install-SMSFlowSqlIntegrationHost.sh',
        'Uninstall-SMSFlowSqlIntegrationHost.sh',
        'SchemaMigrator',
        'sql_integration_v2.sql'
    )
    "$releaseName-docker-host.zip" = @(
        'docker-compose',
        'Dockerfile',
        'config/worker/appsettings.json',
        'schema-migrator/payload'
    )
}

function Assert-FileExists {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required release asset was not found: $Path"
    }
}

function Get-ChecksumMap {
    param([string]$Path)

    $checksums = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^(?<hash>[a-fA-F0-9]{64})\s+(?<name>.+)$') {
            $checksums[$Matches.name.Trim()] = $Matches.hash.ToLowerInvariant()
        }
    }

    return $checksums
}

function Test-ZipContains {
    param(
        [string]$ZipPath,
        [string[]]$ExpectedFragments
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entries = $zip.Entries | ForEach-Object { $_.FullName.Replace('\', '/') }
        foreach ($fragment in $ExpectedFragments) {
            $normalized = $fragment.Replace('\', '/')
            if (-not ($entries | Where-Object { $_ -like "*$normalized*" } | Select-Object -First 1)) {
                throw "ZIP '$ZipPath' does not contain expected entry fragment '$fragment'."
            }
        }
    }
    finally {
        $zip.Dispose()
    }
}

$resolvedAssetDirectory = Resolve-Path $AssetDirectory
foreach ($asset in $requiredAssets) {
    Assert-FileExists -Path (Join-Path $resolvedAssetDirectory $asset)
}

$checksumMap = Get-ChecksumMap -Path (Join-Path $resolvedAssetDirectory 'CHECKSUMS-SHA256.txt')
foreach ($zipName in $requiredAssets | Where-Object { $_ -like '*.zip' }) {
    if (-not $checksumMap.ContainsKey($zipName)) {
        throw "Checksum manifest does not contain '$zipName'."
    }

    $zipPath = Join-Path $resolvedAssetDirectory $zipName
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLowerInvariant()
    if ($actualHash -ne $checksumMap[$zipName]) {
        throw "Checksum mismatch for '$zipName'. Expected $($checksumMap[$zipName]), got $actualHash."
    }

    Test-ZipContains -ZipPath $zipPath -ExpectedFragments $requiredZipEntries[$zipName]
    Write-Host "Smoke-tested $zipName"
}

Write-Host "SMSFlow SQL API $Version release assets passed local smoke testing."
