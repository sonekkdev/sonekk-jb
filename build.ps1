# Builds SonekkJB.ipa on Windows with clang + iPhoneOS SDK. No Mac required.
# Usage:
#   $env:CLANG   = "C:\path\to\clang.exe"
#   $env:IOS_SDK = "C:\path\to\iPhoneOS26.5.sdk"
#   powershell -ExecutionPolicy Bypass -File build.ps1

$ErrorActionPreference = 'Stop'

$clang = if ($env:CLANG) { $env:CLANG } else { 'C:\Users\Shared\llvm\bin\clang.exe' }
$sdk   = if ($env:IOS_SDK) { $env:IOS_SDK } else { 'C:\Users\Shared\sdk\iPhoneOS26.5.sdk' }

if (-not (Test-Path $clang)) { throw "clang not found: $clang (set `$env:CLANG)" }
if (-not (Test-Path $sdk))   { throw "SDK not found: $sdk (set `$env:IOS_SDK)" }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $root 'src'
$out  = Join-Path $root 'out'

if (Test-Path $out) { Remove-Item $out -Recurse -Force }
$appDir = Join-Path $out 'Payload\SonekkJB.app'
New-Item -ItemType Directory -Path $appDir -Force | Out-Null

$binary = Join-Path $appDir 'SonekkJB'
$sources = @(
    (Join-Path $src 'main.m'),
    (Join-Path $src 'JBViewController.m'),
    (Join-Path $src 'JBJailbreakButton.m')
) + (Get-ChildItem (Join-Path $src 'dopamine') -Filter *.m | ForEach-Object { $_.FullName })

& $clang -target arm64-apple-ios16.0 -isysroot $sdk -fobjc-arc -O2 -Wno-deprecated-declarations `
    -I (Join-Path $src 'dopamine') -I $src `
    $sources `
    -framework UIKit -framework Foundation -framework QuartzCore `
    -framework CoreGraphics -framework CoreImage `
    -o $binary
if ($LASTEXITCODE -ne 0) { throw "compile failed: $LASTEXITCODE" }

Copy-Item (Join-Path $src 'Info.plist') (Join-Path $appDir 'Info.plist')
Set-Content -Path (Join-Path $appDir 'PkgInfo') -Value 'APPL????' -NoNewline -Encoding ascii

# Dopamine-derived resources: background photo, spinner, blur mask, theme plist.
$resources = Join-Path $root 'Resources'
if (Test-Path $resources) {
    Copy-Item (Join-Path $resources '*') $appDir -Force
}
Copy-Item (Join-Path $src 'dopamine\Themes.plist') $appDir -Force

# App icons: dark teal tile with a glowing white S.
Add-Type -AssemblyName System.Drawing

function New-AppIcon {
    param([string]$OutPath, [int]$Size)

    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    # Deep blue field.
    $rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,
        ([System.Drawing.Color]::FromArgb(255, 11, 46, 82)),
        ([System.Drawing.Color]::FromArgb(255, 3, 10, 22)), 55
    $g.FillRectangle($brush, $rect)

    # Cyan glow behind the mark.
    $glowRect = New-Object System.Drawing.Rectangle ([int]($Size * 0.02)), ([int]($Size * 0.02)), ([int]($Size * 0.96)), ([int]($Size * 0.96))
    $glow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(26, 46, 170, 255))
    $g.FillEllipse($glow, $glowRect)

    # Spiral mark: 2.6 turns, opening to the right.
    $cx = $Size * 0.5
    $cy = $Size * 0.5
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $hasPrev = $false
    $prevX = 0.0
    $prevY = 0.0
    for ($t = 0.0; $t -le 2.55 * [Math]::PI; $t += 0.06) {
        $r = $Size * (0.050 + 0.0415 * $t)
        $x = $cx + $r * [Math]::Cos($t - [Math]::PI / 2)
        $y = $cy + $r * [Math]::Sin($t - [Math]::PI / 2)
        if ($hasPrev) {
            $path.AddLine([single]$prevX, [single]$prevY, [single]$x, [single]$y)
        }
        $prevX = $x
        $prevY = $y
        $hasPrev = $true
    }

    $halo = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 64, 200, 255)), ([single]($Size * 0.150))
    $halo.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $halo.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $halo.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPath($halo, $path)

    $ink = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(250, 255, 255, 255)), ([single]($Size * 0.072))
    $ink.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $ink.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $ink.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPath($ink, $path)

    $g.Dispose()
    $bitmap.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

New-AppIcon -OutPath (Join-Path $appDir 'AppIcon60x60@2x.png') -Size 120
New-AppIcon -OutPath (Join-Path $appDir 'AppIcon60x60@3x.png') -Size 180
New-AppIcon -OutPath (Join-Path $appDir 'AppIcon1024.png') -Size 1024

$ipa = Join-Path $root 'SonekkJB.ipa'
if (Test-Path $ipa) { Remove-Item $ipa -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($out, $ipa, [System.IO.Compression.CompressionLevel]::Optimal, $false)

"binary: $binary ($((Get-Item $binary).Length) bytes)"
"ipa:    $ipa ($((Get-Item $ipa).Length) bytes)"
