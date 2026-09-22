param([string]$Output = '.d12-reference', [switch]$ValidateOnly)
$ErrorActionPreference = 'Stop'
$captureScript = Join-Path $PSScriptRoot 'd12-capture-reference.py'
$python = if (Get-Command py -ErrorAction SilentlyContinue) { 'py' } else { 'python' }
$arguments = @($captureScript, '--output', $Output)
if ($ValidateOnly) { $arguments += '--validate-only' }
& $python @arguments
exit $LASTEXITCODE
