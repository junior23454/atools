# ATools

## Встановлення

Готовий простий `.exe`-установщик збирається так:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_simple_installer.ps1
```

Результат буде тут:

```text
dist\ATools_Setup.exe
```

Швидкий локальний варіант:

1. Запусти `Install_ATools.cmd`.
2. Скрипт встановить файли в `%LOCALAPPDATA%\ATools`.
3. На робочому столі та в Start Menu з'явиться ярлик `ATools`.

Збірка класичного `.exe`-інсталятора:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_installer.ps1
```

Скрипт підготує `build\app` і, якщо встановлений Inno Setup 6, створить інсталятор у `dist`.

## Автооновлення

ATools читає локальний `version.txt` і порівнює його з:

```text
https://raw.githubusercontent.com/junior23454/atools/main/version.txt
```

Щоб випустити нову версію, онови файли в репозиторії та збільш `version.txt`, наприклад з `1.0.0` до `1.0.1`. Після запуску ATools перевірить GitHub, завантажить zip гілки `main`, замінить `atools.ahk`, `assets`, `sounds`, `tools`, `version.txt` і перезапуститься.
