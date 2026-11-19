# AuroraOOBE

**Aurora Studio OOBE** — интерактивный установщик софта и твиков для Windows (WPF + PowerShell). Устанавливает приложения из каталога (`winget`, прямые ссылки, архивы с паролем через 7-Zip), применяет системные твики, работает с центром обновлений Windows и поддерживает настройку второго монитора.

## 🚀 Быстрый запуск (One-Liner)

Запустите в **PowerShell от имени администратора** — скачивать ZIP не нужно:

```powershell
irm https://raw.githubusercontent.com/5665567667/AuroraOOBE/master/AuroraOOBE.ps1 | iex
```

> ⚠️ Для ручного запуска клонируйте репозиторий целиком — скрипт загружает интерфейс из файла `Interface.xaml`, лежащего рядом с `AuroraOOBE.ps1` (через `$PSScriptRoot`).

## 📁 Структура проекта

| Файл | Описание |
|---|---|
| `AuroraOOBE.ps1` | Логика установщика (каталог приложений, твики, загрузка XAML) |
| `Interface.xaml` | Вся разметка WPF-интерфейса (UTF-8 with BOM) |
| `.gitattributes` | Защита кириллицы: `working-tree-encoding=UTF-8-BOM`, CRLF для `.ps1`/`.xaml` |
| `.github/workflows/lint.yml` | CI: PSScriptAnalyzer при каждом пуше |
| `LICENSE` | MIT |

## 🧩 Возможности

* **Каталог приложений**: архиваторы, браузеры, игровые лаунчеры, Minecraft-серверы, Discord, бенчмарки, оптимизаторы, Raven Store.
* **AmneziaWG**: установка MSI с GitHub Releases + открытие `https://warp.sakeen.ru` для генерации конфига.
* **Raven Store**: сначала ставится `Microsoft.WindowsAppRuntime.1.6`, затем Raven; после установки скрипт спрашивает, удалять ли пакет `WindowsStore`.
* **Твики 2-го монитора**: панель `GrpDualMonitor` скрыта по умолчанию (`Visibility="Collapsed"`) и появляется автоматически при `[System.Windows.Forms.Screen]::AllScreens.Count -ge 2` либо по кнопке «Показать принудительно».
* **Архивы с паролем**: для источников allrepack / mloads / 1progs в каталоге задано поле `Password`, которое передаётся в 7-Zip как `-p"$($App.Password)"`.
* **Центр обновлений Windows**: поиск и установка через WUA COM API.
* **Defender**: опциональное отключение realtime-защиты и службы WinDefend.

## 🔐 Проверка целостности (SHA256)

| Файл | SHA256 |
|---|---|
| `AuroraOOBE.ps1` | `4be19af7c3ac36d1277485d9de0b7c5f0ed29af51e6478a7cdd8676d06391765` |
| `Interface.xaml` | `c7dfe2f82388584e2686348a6ced9e4ee365725386e3beee90080cc5337ecdf2` |

Проверка в PowerShell:

```powershell
Get-FileHash .\AuroraOOBE.ps1 -Algorithm SHA256
```

## 🛠 Требования

* Windows 10 / 11, PowerShell 5.1+
* Рекомендуется запуск от имени администратора (реестровые твики, удаление пакетов, Defender)
* Winget (устанавливает aria2 и 7-Zip автоматически)

## ⚖️ Лицензия

MIT — см. [LICENSE](LICENSE).
