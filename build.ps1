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
& $clang -target arm64-apple-ios16.0 -isysroot $sdk -fobjc-arc -O2 `
    (Join-Path $src 'main.m') (Join-Path $src 'JBViewController.m') `
    -framework UIKit -framework Foundation -framework QuartzCore `
    -framework CoreGraphics `
    -o $binary
if ($LASTEXITCODE -ne 0) { throw "compile failed: $LASTEXITCODE" }

Copy-Item (Join-Path $src 'Info.plist') (Join-Path $appDir 'Info.plist')
Set-Content -Path (Join-Path $appDir 'PkgInfo') -Value 'APPL????' -NoNewline -Encoding ascii

# App icons: dark teal tile with a glowing white S.
Add-Type -AssemblyName System.Drawing

function New-AppIcon {
    param([string]$Path, [int]$Size)

    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    $rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,
        ([System.Drawing.Color]::FromArgb(255, 12, 40, 26)),
        ([System.Drawing.Color]::FromArgb(255, 3, 12, 9)), 60
    $g.FillRectangle($brush, $rect)

    $glow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(46, 51, 242, 128))
    $glowRect = New-Object System.Drawing.Rectangle ([int]($Size * 0.08)), ([int]($Size * 0.08)), ([int]($Size * 0.84)), ([int]($Size * 0.84))
    $g.FillEllipse($glow, $glowRect)

    $font = New-Object System.Drawing.Font 'Segoe UI', ([single]($Size * 0.50)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(240, 255, 255, 255))
    $textRect = New-Object System.Drawing.RectangleF 0, 0, $Size, $Size
    $g.DrawString('S', $font, $ink, $textRect, $format)

    $g.Dispose()
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

New-AppIcon -Path (Join-Path $appDir 'AppIcon60x60@2x.png') -Size 120
New-AppIcon -Path (Join-Path $appDir 'AppIcon60x60@3x.png') -Size 180
New-AppIcon -Path (Join-Path $appDir 'AppIcon1024.png') -Size 1024

$ipa = Join-Path $root 'SonekkJB.ipa'
if (Test-Path $ipa) { Remove-Item $ipa -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($out, $ipa, [System.IO.Compression.CompressionLevel]::Optimal, $false)

"binary: $binary ($((Get-Item $binary).Length) bytes)"
"ipa:    $ipa ($((Get-Item $ipa).Length) bytes)"
