param(
    [string]$Version = '0.3.0',
    [string]$AssetDirectory = 'artifacts/smoke/v0.3.0',
    [string]$WorkDirectory = 'artifacts/demo-smoke/v0.3.0',
    [string]$ProjectName = 'smsflow-sql-api-demo-smoke'
)

$ErrorActionPreference = 'Stop'

$releaseName = "smsflow-sql-api-$Version"
$assetDirectoryPath = Join-Path (Get-Location) $AssetDirectory
$workDirectoryPath = Join-Path (Get-Location) $WorkDirectory
$dockerZipPath = Join-Path $assetDirectoryPath "$releaseName-docker-host.zip"
$bundleDirectory = Join-Path $workDirectoryPath 'docker-host'
$composeFile = Join-Path (Get-Location) 'deploy/demo/try-it-in-10-minutes/docker-compose.yml'
$workerImage = "smsflow-sql-api-worker:$Version"

function Assert-WorkerLogsHealthy {
    $logs = & docker compose -p $ProjectName -f $composeFile logs --no-log-prefix worker 2>&1
    $text = ($logs -join [Environment]::NewLine)
    if ($text -match 'You must install or update \.NET' -or
        $text -match 'Unhandled exception' -or
        $text -match 'framework_version=Microsoft\.NETCore\.App') {
        Write-Host $text
        throw 'Worker container logs contain a runtime startup failure.'
    }
}

function Invoke-LoggedCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    Write-Host "> $FilePath $($Arguments -join ' ')"
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE`: $FilePath $($Arguments -join ' ')"
    }
}

function Download-DockerAsset {
    param([string]$DestinationPath)

    $url = "https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v$Version/$releaseName-docker-host.zip"
    Write-Host "Downloading $url"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $DestinationPath) | Out-Null
    Invoke-WebRequest -Uri $url -OutFile $DestinationPath
}

if (-not (Test-Path -LiteralPath $dockerZipPath)) {
    Download-DockerAsset -DestinationPath $dockerZipPath
}

if (-not (Test-Path -LiteralPath $composeFile)) {
    throw "Demo compose file was not found: $composeFile"
}

if (Test-Path -LiteralPath $workDirectoryPath) {
    Remove-Item -LiteralPath $workDirectoryPath -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $bundleDirectory | Out-Null

Expand-Archive -LiteralPath $dockerZipPath -DestinationPath $bundleDirectory -Force

$workerDockerContext = Join-Path $bundleDirectory 'worker'
$workerDockerfile = Join-Path $workerDockerContext 'Dockerfile'
if (-not (Test-Path -LiteralPath $workerDockerfile)) {
    throw "Worker Dockerfile was not found in the release bundle: $workerDockerfile"
}

$previousImageEnv = $env:SMSFLOW_SQL_API_WORKER_IMAGE
$env:SMSFLOW_SQL_API_WORKER_IMAGE = $workerImage

try {
    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('build', '-t', $workerImage, $workerDockerContext)

    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('compose', '-p', $ProjectName, '-f', $composeFile, 'config')
    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('compose', '-p', $ProjectName, '-f', $composeFile, 'up', '-d', 'sqlserver')
    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('compose', '-p', $ProjectName, '-f', $composeFile, 'run', '--rm', 'schema')
    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('compose', '-p', $ProjectName, '-f', $composeFile, 'up', '-d', 'worker')
    Start-Sleep -Seconds 8
    Assert-WorkerLogsHealthy
    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('compose', '-p', $ProjectName, '-f', $composeFile, 'run', '--rm', 'seed')
    $processed = $false
    for ($attempt = 1; $attempt -le 18; $attempt++) {
        Start-Sleep -Seconds 5
        Assert-WorkerLogsHealthy
        & docker compose -p $ProjectName -f $composeFile run --rm assert
        if ($LASTEXITCODE -eq 0) {
            $processed = $true
            break
        }

        Write-Host "Waiting for worker to process simulated messages... ($attempt/18)"
    }

    if (-not $processed) {
        throw 'Demo messages were not processed by the worker within the expected time.'
    }

    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('compose', '-p', $ProjectName, '-f', $composeFile, 'run', '--rm', 'validate')
    Invoke-LoggedCommand -FilePath 'docker' -Arguments @('compose', '-p', $ProjectName, '-f', $composeFile, 'logs', '--tail', '120', 'worker')

    Write-Host "SMSFlow SQL API $Version demo smoke test passed."
}
finally {
    docker compose -p $ProjectName -f $composeFile down -v
    $env:SMSFLOW_SQL_API_WORKER_IMAGE = $previousImageEnv
}
