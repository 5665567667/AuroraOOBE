# AuroraOOBE.ps1 – Aurora Studio OOBE installer (logic only; UI lives in Interface.xaml)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# One-Liner support: irm .../AuroraOOBE.ps1 | iex  =>  download Interface.xaml next to the script
if (-not $PSScriptRoot) { $script:PSScriptRoot = if ($PWD -and (Test-Path (Join-Path $PWD "Interface.xaml"))) { $PWD.Path } else { (Get-Location).Path } }
$XamlFile = Join-Path $PSScriptRoot "Interface.xaml"
if (-not (Test-Path $XamlFile)) {
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/5665567667/AuroraOOBE/master/Interface.xaml" -OutFile $XamlFile -UseBasicParsing
    } catch { throw "Interface.xaml not found!" }
}

try {
    $Xaml = Get-Content $XamlFile -Raw -Encoding UTF8
    $Reader = New-Object System.Xml.XmlNodeReader ([xml]$Xaml)
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
} catch { Write-Error "Ошибка загрузки XAML: $_"; exit }
$BaseInstallDir  = "C:\Program Files\AuroraApps"
$BaseDownloadDir = "C:\AuroraDownloads_Test"
$SevenZipExe     = "C:\Program Files\7-Zip\7z.exe"
$Global:AriaExe  = ""
$InstallLog      = @()
$DisableDefender = $false
$CheckBoxes      = @{}

$AppCatalog = [ordered]@{
    "Lib_7Zip"      = @{ Name="7-Zip"; Cat="1 Библиотеки"; Type="Winget"; Id="7zip.7zip" }
    "Lib_WinRAR"    = @{ Name="WinRAR"; Cat="1 Библиотеки"; Type="Winget"; Id="RARLab.WinRAR" }
    "Lib_Codecs"    = @{ Name="X Codec Pack"; Cat="1 Библиотеки"; Type="Url"; Url="https://files.xcodecpack.org/XCodecPack.exe"; Ext=".exe" }
    "Lib_VLC"       = @{ Name="VLC Media Player"; Cat="1 Библиотеки"; Type="Winget"; Id="VideoLAN.VLC" }
    "Lib_VCRedist"  = @{ Name="Visual C++ Redist AIO"; Cat="1 Библиотеки"; Type="Url"; Url="https://github.com/abbodi1406/vcredist/releases/download/v0.107.0/VisualCppRedist_AIO_x86_x64.exe"; Ext=".exe" }
    "Lib_DirectX"   = @{ Name="DirectX End-User"; Cat="1 Библиотеки"; Type="Winget"; Id="Microsoft.DirectX" }
    "Lib_MakuTyper" = @{ Name="MakuTyper"; Cat="1 Библиотеки"; Type="Url"; Url="https://adderly.top/makutyper/MakuTyper_Setup.exe"; Ext=".exe" }
    "Lib_MakuFlash" = @{ Name="MakuFlash"; Cat="1 Библиотеки"; Type="Url"; Url="https://adderly.top/MakuFlash.exe"; Ext=".exe" }
    "Lib_Amnezia"   = @{ Name="AmneziaWG"; Cat="1 Библиотеки"; Type="CustomAmnezia"; Url="https://github.com/amnezia-vpn/amneziawg-windows-client/releases/download/v3.1.0/amneziawg-amd64-3.1.0.msi" }

    "Game_Epic"     = @{ Name="Epic Games Store"; Cat="2 Лаунчеры"; Type="Winget"; Id="EpicGames.EpicGamesLauncher" }
    "Game_Steam"    = @{ Name="Steam"; Cat="2 Лаунчеры"; Type="Winget"; Id="Valve.Steam" }
    "Game_Lesta"    = @{ Name="Lesta Game Center"; Cat="2 Лаунчеры"; Type="Url"; Url="https://lesta.ru/gamecenter/"; Ext=".url" }
    "Game_Astrum"   = @{ Name="Astrum Play"; Cat="2 Лаунчеры"; Type="Url"; Url="https://astrum.online/"; Ext=".url" }
    "Game_VKPlay"   = @{ Name="VK Play"; Cat="2 Лаунчеры"; Type="Url"; Url="https://vkplay.ru/"; Ext=".url" }
    "Game_GOG"      = @{ Name="GOG Galaxy"; Cat="2 Лаунчеры"; Type="Winget"; Id="GOG.Galaxy" }
    "Game_Roblox"   = @{ Name="Roblox"; Cat="2 Лаунчеры"; Type="Winget"; Id="Roblox.Roblox" }
    "Game_EA"       = @{ Name="EA App"; Cat="2 Лаунчеры"; Type="Winget"; Id="ElectronicArts.EADesktop" }
    "Game_Ubi"      = @{ Name="Ubisoft Connect"; Cat="2 Лаунчеры"; Type="Winget"; Id="Ubisoft.Connect" }
    "Game_Battle"   = @{ Name="Battle.net"; Cat="2 Лаунчеры"; Type="Winget"; Id="Blizzard.BattleNet" }
    "Game_Itch"     = @{ Name="itch.io"; Cat="2 Лаунчеры"; Type="Winget"; Id="ItchIo.Itch" }

    "Br_Chrome"     = @{ Name="Google Chrome"; Cat="3 Браузеры"; Type="Winget"; Id="Google.Chrome" }
    "Br_Yandex"     = @{ Name="Yandex Browser"; Cat="3 Браузеры"; Type="Winget"; Id="Yandex.Browser" }
    "Br_Opera"      = @{ Name="Opera"; Cat="3 Браузеры"; Type="Winget"; Id="Opera.Opera" }
    "Br_OperaGX"    = @{ Name="Opera GX"; Cat="3 Браузеры"; Type="Winget"; Id="Opera.OperaGX" }
    "Br_Brave"      = @{ Name="Brave"; Cat="3 Браузеры"; Type="Winget"; Id="Brave.Brave" }
    "Br_Vivaldi"    = @{ Name="Vivaldi"; Cat="3 Браузеры"; Type="Winget"; Id="Vivaldi.Vivaldi" }
    "Br_Min"        = @{ Name="Min Browser"; Cat="3 Браузеры"; Type="Winget"; Id="Min.Min" }
    "Br_PaleMoon"   = @{ Name="Pale Moon"; Cat="3 Браузеры"; Type="Winget"; Id="MoonchildProductions.PaleMoon" }

    "Disc_Main"     = @{ Name="Discord"; Cat="4 Discord"; Type="Winget"; Id="Discord.Discord" }

    "MC_Borealis"   = @{ Name="Borealis"; Cat="5 Minecraft"; Type="Url"; Url="https://borealis.su/"; Ext=".url" }
    "MC_Arsland"    = @{ Name="Arsland"; Cat="5 Minecraft"; Type="Url"; Url="https://arsland.ru/"; Ext=".url" }
    "MC_Gravity"    = @{ Name="GravityCraft"; Cat="5 Minecraft"; Type="Url"; Url="https://gravitycraft.ru/"; Ext=".url" }
    "MC_LoliLand"   = @{ Name="LoliLand"; Cat="5 Minecraft"; Type="Url"; Url="https://loliland.net/"; Ext=".url" }
    "MC_McSkill"    = @{ Name="McSkill"; Cat="5 Minecraft"; Type="Url"; Url="https://mcskill.ru/"; Ext=".url" }
    "MC_NextMine"   = @{ Name="NextMine"; Cat="5 Minecraft"; Type="Url"; Url="https://nextmine.ru/"; Ext=".url" }
    "MC_Victory"    = @{ Name="VictoryCraft"; Cat="5 Minecraft"; Type="Url"; Url="https://victorycraft.ru/"; Ext=".url" }

    "Opt_Win10Tweaker" = @{ Name="Win 10 Tweaker"; Cat="6 Оптимизация"; Type="Url"; Url="https://allrepack.ru/wp-content/uploads/2020/06/Win_10_Tweaker_Pro_19.4.zip"; Password="allrepack"; Ext=".zip" }
    "Opt_WiseReg"      = @{ Name="Wise Registry Cleaner"; Cat="6 Оптимизация"; Type="Url"; Url="https://mloads.com/download?a%3AaHR0cHM6Ly9tbGRvd25sb2FkLnJ1L2ZpbGVzL2xvYWQxLzAwOC9XaXNlX1JlZ2lzdHJ5X0NsZWFuZXJfdjExLjMuMi43MzQucmFy"; Password="mloads"; Ext=".rar" }
    "Opt_Revo"         = @{ Name="Revo Uninstaller Pro"; Cat="6 Оптимизация"; Type="Url"; Url="https://allrepack.ru/wp-content/uploads/2026/03/Revo.Uninstaller.Pro.v5.5.4.rar"; Password="allrepack"; Ext=".rar" }
    "Opt_Glary"        = @{ Name="Glary Utilities Pro"; Cat="6 Оптимизация"; Type="Url"; Url="https://mloads.com/download?a%3AaHR0cHM6Ly9tbGRvd25sb2FkLnJ1L2ZpbGVzL2xvYWQyLzAwNS9HbGFyeV9VdGlsaXRpZXNfdjYuNDkuMC41My5yYXI%3D"; Password="mloads"; Ext=".rar" }
    "Opt_Shell"        = @{ Name="Nilesoft Shell (Glossy)"; Cat="6 Оптимизация"; Type="Url"; Url="https://keysoft.store/wp-content/uploads/2026/09/shell-glossy.zip"; Ext=".zip" }
    "Opt_MakuTweaker"  = @{ Name="MakuTweaker"; Cat="6 Оптимизация"; Type="Url"; Url="https://adderly.top/makutweaker"; Ext=".exe" }
    "Opt_Windhawk"     = @{ Name="Windhawk"; Cat="6 Оптимизация"; Type="Winget"; Id="RamenSoftware.Windhawk" }

    "Bench_3DMark11"    = @{ Name="3DMark 11"; Cat="7 Benchmarks"; Type="Winget"; Id="Futuremark.3DMark11" }
    "Bench_Superposition" = @{ Name="Unigine Superposition"; Cat="7 Benchmarks"; Type="Winget"; Id="Unigine.SuperpositionBenchmark" }
    "Bench_FurMark"     = @{ Name="FurMark"; Cat="7 Benchmarks"; Type="Url"; Url="https://github.com/AddIt-02/FurMark/archive/refs/heads/main.zip"; Ext=".zip" }
    "Bench_Cinebench"   = @{ Name="Cinebench 2024"; Cat="7 Benchmarks"; Type="Url"; Url="https://mx-app-blob-prod.maxon.net/mx-package-production/website/windows/maxon/cinebench/Cinebench2026_win_x86_64.zip"; Ext=".zip" }
    "Bench_PassMark"    = @{ Name="PassMark PerformanceTest"; Cat="7 Benchmarks"; Type="Url"; Url="https://files.1progs.net/wp-content/uploads/2023/09/PassMark-PerformanceTest-10.2-Build-1002.zip"; Password="1progs"; Ext=".zip" }
    "Bench_Blender"     = @{ Name="Blender Benchmark"; Cat="7 Benchmarks"; Type="Url"; Url="https://www.majorgeeks.com/mg/get/blender_benchmark,1.html"; Ext=".exe" }
    "Bench_RAMTest"     = @{ Name="RAM Test Pro"; Cat="7 Benchmarks"; Type="Url"; Url="https://pcstonks.com/s/KiUhvH"; Ext=".exe" }
    "Bench_AIDA64"      = @{ Name="AIDA64 Extreme"; Cat="7 Benchmarks"; Type="Url"; Url="https://allrepack.ru/wp-content/uploads/2026/08/AIDA64_8.40.8500.rar"; Password="allrepack"; Ext=".rar" }
    "Bench_CDM"         = @{ Name="CrystalDiskMark"; Cat="7 Benchmarks"; Type="Url"; Url="https://www.softsalad.ru/software/sistema/optimizaciya/crystaldiskmark/download/381?expires=1794954520&signature=49daa63cb14ec2c32bfa849a535dcd7e9249cbd4901215a0e463e7f771f1759c&CrystalDiskMark9_0_3.zip"; Ext=".zip" }
    "Bench_ASSSD"       = @{ Name="AS SSD Benchmark"; Cat="7 Benchmarks"; Type="Url"; Url="https://www.softsalad.ru/software/sistema/utility/as-ssd-benchmark/download/1635?expires=1794954584&signature=dc2c0a54f03c976062243a81f4edf3520f635286adb84ce256d55cf3cd5329d8&AS%20SSD%20Benchmark.zip"; Ext=".zip" }
    "Bench_HDTune"      = @{ Name="HD Tune Pro"; Cat="7 Benchmarks"; Type="Url"; Url="https://allrepack.ru/wp-content/uploads/2026/09/hd_tune_pro_6.00.rar"; Password="allrepack"; Ext=".rar" }
    "Bench_3DMarkStorage" = @{ Name="3DMark Storage"; Cat="7 Benchmarks"; Type="Url"; Url="https://www.techpowerup.com/download/futuremark-3dmark-timespy-raytracing/"; Ext=".url" }

    "Store_Raven" = @{ Name="Raven Store + SDK"; Cat="8 Store"; Type="CustomRaven" }
}

function Log { param($msg); $Window.FindName("StatusText").Text = $msg; $InstallLog += $msg; [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, "Background") }
function DoEvents { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, "Background") }

function BuildUI {
    $Categories = $AppCatalog.Values | Select-Object Cat -Unique
    foreach ($Cat in $Categories.Cat) {
        $Group = New-Object System.Windows.Controls.GroupBox
        $Group.Header = $Cat; $Group.Foreground = "White"; $Group.Margin = "0,0,0,10"
        $Stack = New-Object System.Windows.Controls.StackPanel
        
        $Items = $AppCatalog.GetEnumerator() | Where-Object { $_.Value.Cat -eq $Cat }
        foreach ($Item in $Items) {
            $Cb = New-Object System.Windows.Controls.CheckBox
            $Cb.Content = $Item.Value.Name; $Cb.Tag = $Item.Key; $Cb.Foreground = "White"; $Cb.Margin = "5,2,0,0"
            if ($Item.Key -in @("Lib_7Zip","Lib_VCRedist","Lib_DirectX","Br_Chrome","Disc_Main")) { $Cb.IsChecked = $true }
            $CheckBoxes[$Item.Key] = $Cb
            $Stack.Children.Add($Cb) | Out-Null
        }
        $Group.Content = $Stack
        $Window.FindName("ContentPanel").Children.Add($Group) | Out-Null
    }
}

$Window.FindName("BtnArch7Zip").Add_Click({ $CheckBoxes["Lib_7Zip"].IsChecked=$true; $CheckBoxes["Lib_WinRAR"].IsChecked=$false; ShowMain })
$Window.FindName("BtnArchWinRar").Add_Click({ $CheckBoxes["Lib_7Zip"].IsChecked=$false; $CheckBoxes["Lib_WinRAR"].IsChecked=$true; ShowMain })
$Window.FindName("BtnArchBoth").Add_Click({ $CheckBoxes["Lib_7Zip"].IsChecked=$true; $CheckBoxes["Lib_WinRAR"].IsChecked=$true; ShowMain })

function ShowMain {
    $Window.FindName("PanelArchWizard").Visibility = "Collapsed"
    $Window.FindName("MainTab").Visibility = "Visible"
    $Window.FindName("BottomPanel").Visibility = "Visible"
    BuildUI
    if ([System.Windows.Forms.Screen]::AllScreens.Count -ge 2) { $Window.FindName("GrpDualMonitor").Visibility = "Visible" }
}

$Window.FindName("BtnNoDefender").Add_Click({ $DisableDefender=$true; [System.Windows.MessageBox]::Show("В тесте Defender НЕ отключается, флаг установлен.") })
$Window.FindName("BtnKeepDefender").Add_Click({ $DisableDefender=$false })
$Window.FindName("BtnForceShowMonitor").Add_Click({ $Window.FindName("GrpDualMonitor").Visibility = "Visible" })

$Window.FindName("BtnCheckUpdates").Add_Click({
    Log "Поиск обновлений..."
    try {
        $S = New-Object -ComObject Microsoft.Update.Session
        $R = $S.CreateUpdateSearcher().Search("IsInstalled=0 and Type='Software'")
        if ($R.Updates.Count -gt 0) {
            $Window.FindName("PanelUpdates").Visibility = "Visible"
            $Window.FindName("TxtUpdateInfo").Text = "Найдено $($R.Updates.Count) обновлений."
        } else { [System.Windows.MessageBox]::Show("Обновлений не найдено.") }
    } catch { [System.Windows.MessageBox]::Show("Ошибка проверки обновлений.") }
})

$Window.FindName("BtnInstallUpdates").Add_Click({
    Log "Установка найденных обновлений Windows..."
    try {
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Searcher = $Session.CreateUpdateSearcher()
        $Result = $Searcher.Search("IsInstalled=0 and Type='Software'")
        if ($Result.Updates.Count -gt 0) {
            $Coll = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($U in $Result.Updates) { $Coll.Add($U) | Out-Null }
            $Downloader = $Session.CreateUpdateDownloader(); $Downloader.Updates = $Coll; $Downloader.Download() | Out-Null
            $Installer = $Session.CreateUpdateInstaller(); $Installer.Updates = $Coll
            $InstallResult = $Installer.Install()
            Log ("Обновления установлены. Код результата: " + $InstallResult.ResultCode)
        }
    } catch { [System.Windows.MessageBox]::Show("Ошибка установки обновлений: $_") }
})

$Window.FindName("BtnStartInstall").Add_Click({
    $Window.FindName("BtnStartInstall").IsEnabled = $false
    Log "Подготовка инструментов..."
    winget install --id aria2.aria2 -e --silent --accept-source-agreements | Out-Null
    winget install --id 7zip.7zip -e --silent --accept-source-agreements | Out-Null
    $Global:AriaExe = (Get-Command aria2c.exe -ErrorAction SilentlyContinue).Source
    if (-not $Global:AriaExe) { $Global:AriaExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "aria2c.exe" -Recurse | Select -First 1 -Expand FullName }

    foreach ($Key in $CheckBoxes.Keys) {
        if ($CheckBoxes[$Key].IsChecked) { Install-App $AppCatalog[$Key] }
    }
    Apply-Tweaks
    Finish-Setup
})

function Install-App($App) {
    Log "Установка: $($App.Name)..."
    DoEvents
    $InstDir = Join-Path $BaseInstallDir $App.Cat
    $DlDir = Join-Path $BaseDownloadDir $App.Cat
    New-Item -ItemType Directory -Force -Path $InstDir | Out-Null
    New-Item -ItemType Directory -Force -Path $DlDir | Out-Null

    switch ($App.Type) {
        "Winget" { winget install --id $App.Id -e --silent --accept-source-agreements | Out-Null }
        "Url" {
            $Fn = Split-Path $App.Url -Leaf; if ($Fn -match '\?') { $Fn = "dl_$($App.Name).bin" }
            $Fp = Join-Path $DlDir $Fn
            if ($Global:AriaExe) { & $Global:AriaExe -x 16 -s 16 -d $DlDir -o $Fn $App.Url | Out-Null } else { Invoke-WebRequest -Uri $App.Url -OutFile $Fp }
            
            if (Test-Path $Fp) {
                if ($App.Ext -in @(".zip",".rar",".7z")) {
                    $PwArg = if ($App.Password) { "-p`"$($App.Password)`"" } else { "-p`"`"" }
                    & $SevenZipExe x "$Fp" "-o$InstDir" $PwArg -y | Out-Null
                    $I = Get-ChildItem $InstDir -Include *.exe,*.msi -Recurse | Select -First 1
                    if ($I) { Run-Installer $I.FullName }
                } elseif ($App.Ext -eq ".url") { Start-Process $App.Url }
                else { Run-Installer $Fp }
                Remove-Item $Fp -Force -ErrorAction SilentlyContinue
            }
        }
        "CustomAmnezia" {
            $Mp = Join-Path $DlDir "amnezia.msi"
            if ($Global:AriaExe) { & $Global:AriaExe -d $DlDir -o "amnezia.msi" $App.Url | Out-Null } else { Invoke-WebRequest -Uri $App.Url -OutFile $Mp }
            if (Test-Path $Mp) { Start-Process msiexec.exe -ArgumentList "/i `"$Mp`" /qn" -Wait; Remove-Item $Mp }
            Start-Process "https://warp.sakeen.ru"  # генерация конфига в браузере
        }
        "CustomRaven" {
            winget install --id Microsoft.WindowsAppRuntime.1.6 -e --silent --accept-source-agreements | Out-Null
            winget install --id mjishnu.Raven -e --silent --accept-source-agreements | Out-Null
            $Re = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "Raven.exe" -Recurse | Select -First 1 -Expand FullName
            if ($Re) { reg add "HKCR\ms-windows-store\shell\open\command" /ve /t REG_SZ /d "`"$Re`" `%1`"" /f | Out-Null }
            $Ans = [System.Windows.MessageBox]::Show(
                "Raven Store установлен и перехват ms-windows-store настроен.`n`nУдалить оригинальный пакет Microsoft Store (WindowsStore)?",
                "AuroraOOBE",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question)
            if ($Ans -eq [System.Windows.DialogResult]::Yes) {
                Get-AppxPackage *WindowsStore* | Remove-AppxPackage -ErrorAction SilentlyContinue
                Log "Пакет WindowsStore удалён."
            }
        }
    }
}

function Run-Installer($Path) {
    $Ext = [IO.Path]::GetExtension($Path).ToLower()
    if ($Ext -eq ".msi") { Start-Process msiexec.exe -ArgumentList "/i `"$Path`" /qn" -Wait }
    elseif ($Ext -eq ".exe") { Start-Process $Path -ArgumentList "/S" -Wait }
}

function Apply-Tweaks {
    Log "Применение твиков..."
    if ($Window.FindName("GrpDualMonitor").Visibility -eq "Visible") {
        if ($Window.FindName("ChkTaskbar").IsChecked) { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v MMTaskbarEnabled /t REG_DWORD /d 1 /f | Out-Null }
        if ($Window.FindName("ChkCursor").IsChecked) { reg add "HKCU\Control Panel\Desktop" /v MouseCornerClipLength /t REG_SZ /d 0 /f | Out-Null }
        if ($Window.FindName("ChkMPO").IsChecked) { reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v OverlayTestMode /t REG_DWORD /d 5 /f | Out-Null }
    }
    if ($DisableDefender) {
        Log "Отключение Microsoft Defender..."
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        sc.exe config WinDefend start= disabled | Out-Null
        Stop-Service WinDefend -Force -ErrorAction SilentlyContinue
    }
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service DiagTrack -StartupType Disabled
}

function Finish-Setup {
    $Window.FindName("MainTab").Visibility = "Collapsed"
    $Window.FindName("BottomPanel").Visibility = "Collapsed"
    $Window.FindName("PanelFinish").Visibility = "Visible"
    $Report = "Установлено приложений: $($InstallLog.Count)`n`nЛог операций:`n" + ($InstallLog -join "`n")
    $Window.FindName("TxtReport").Text = $Report
}

$Window.FindName("BtnClose").Add_Click({ $Window.Close() })
$Window.ShowDialog() | Out-Null