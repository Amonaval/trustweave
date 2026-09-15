$ErrorActionPreference = 'Stop'

function Read-Text($path) {
  if (-not (Test-Path $path)) { throw "Required file not found: $path" }
  return [System.IO.File]::ReadAllText((Resolve-Path $path))
}

function Write-Text($path, $content) {
  [System.IO.File]::WriteAllText((Resolve-Path $path), $content, (New-Object System.Text.UTF8Encoding($false)))
}

function Ensure-I18nToken($path, $token, $value) {
  $text = Read-Text $path
  if ($text -match "(?m)^\s*$([regex]::Escape($token))\s*:") {
    Write-Host "[skip] $token already exists in $path"
    return
  }
  $marker = '} as const;'
  $idx = $text.LastIndexOf($marker)
  if ($idx -lt 0) { throw "Could not find '$marker' in $path" }
  $line = "  $token`: `"$value`",`r`n"
  $text = $text.Insert($idx, $line)
  Write-Text $path $text
  Write-Host "[ok] added $token to $path"
}

function Ensure-DesktopMoreReopens($path, $classNameFragment) {
  $text = Read-Text $path
  # Add the native open attribute only to the named desktop <details> element.
  # This preserves all surrounding E9/E10 code and causes the section to reopen on navigation/rerender.
  $pattern = "<details(?![^>]*\\bopen\\b)([^>]*className=\\{`[^`]*$([regex]::Escape($classNameFragment))[^`]*`\\}[^>]*)>"
  $regex = New-Object System.Text.RegularExpressions.Regex($pattern)
  $updated = $regex.Replace($text, '<details open$1>', 1)
  if ($updated -eq $text) {
    if ($text -match "<details[^>]*\\bopen\\b[^>]*$([regex]::Escape($classNameFragment))") {
      Write-Host "[skip] desktop More already persistent in $path"
      return
    }
    throw "Could not locate desktop More details element '$classNameFragment' in $path. No file was changed."
  }
  Write-Text $path $updated
  Write-Host "[ok] desktop More persistence enabled in $path"
}

Ensure-I18nToken 'lib/i18n/messages/en.ts' 'AmenitiesTxt' 'Amenities'
Ensure-I18nToken 'lib/i18n/messages/hi.ts' 'AmenitiesTxt' 'सुविधाएँ'
Ensure-I18nToken 'lib/i18n/messages/mr.ts' 'AmenitiesTxt' 'सुविधा'

Ensure-DesktopMoreReopens 'components/NetworkApp.tsx' 'family-nav-more'
Ensure-DesktopMoreReopens 'components/TemplateNetworkApp.tsx' 'product-nav-more'

if (Test-Path 'components/shared/NetworkPostsPanel.tsx') {
  Write-Host '[info] E9 NetworkPostsPanel.tsx exists. This hotfix intentionally did not modify or replace it.'
} else {
  Write-Warning 'E9 NetworkPostsPanel.tsx is missing from this working copy. Restore it from your E9/E10 source before continuing E9 validation.'
}

Write-Host ''
Write-Host 'Hotfix applied. Recommended next commands:'
Write-Host '  npm run build'
Write-Host '  npm run validate:showcase-flow-repair'
Write-Host '  npm run validate:showcase-stabilization'
