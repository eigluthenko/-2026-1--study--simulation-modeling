# Лабораторная работа №1: Подготовка стенда. Модель экспоненциального роста

## Репозитории

### GitHub

- [Основной репозиторий](https://github.com/eigluthenko/-2026-1--study--simulation-modeling)
- [Папка лабораторной работы №1](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/tree/master/labs/lab01)
- [Релиз lab01](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/releases/tag/v1.0.1)
- [CHANGELOG](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/blob/master/CHANGELOG.md)

### GitVerse

- [Основной репозиторий](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling)
- [Папка лабораторной работы №1](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/labs/lab01)
- [Релиз lab01](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/releases/tag/v1.0.1)
- [CHANGELOG](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/CHANGELOG.md)

## Состав лабораторной работы

- `project/` — Julia-проект с моделью экспоненциального роста `du/dt = α·u`, численным решением (RK4), аналитикой, параметрическим сканированием, скриптами, CSV-таблицами, графиками, markdown-документами и notebook-файлами;
- `report/` — исходник отчёта Quarto и собранные PDF/DOCX;
- `presentation/` — исходник презентации Quarto и собранные PDF/HTML/PPTX.

## Основные результаты

- освоены инструменты программной инженерии: семантическое версионирование, общепринятые коммиты, git, ssh, gpg;
- реализована модель экспоненциального роста методом Рунге–Кутты 4-го порядка;
- базовый сценарий `α = 0.3`: `u(10) = 20.0855 = e³`, время удвоения `T₂ = 2.31`, максимальная погрешность `≈ 4·10⁻⁷`;
- параметрическое исследование на сетке `α ∈ {0.1, 0.3, 0.5, 0.8, 1.0}` подтвердило закон `T₂ = ln2/α`;
- численное решение согласуется с аналитическим `u(t) = u₀e^{α t}`;
- сформированы CSV-таблицы, графики PNG, два markdown-документа и два исполняемых ipynb-ноутбука;
- подготовлены полный отчёт Quarto и презентация Quarto.

## Видео

### RuTube

- [Плейлист лабораторной работы №1](https://rutube.ru/plst/1655836)
- [Выполнение лабораторной работы №1](https://rutube.ru/video/84bca2581722f9667942d4cf3f3b28a7/)
- [Подготовка отчета](https://rutube.ru/video/25a4b11fc5162b92e2904e516e788091/)
- [Подготовка презентации](https://rutube.ru/video/966876aec33f56c21b552a56b0d6310d/)
- [Защита презентации](https://rutube.ru/video/3ac051041c16fcc7207f2406d4c78406/)

### VK Video

- [Плейлист лабораторной работы №1](https://vkvideo.ru/playlist/-202243462_8)
- [Выполнение лабораторной работы №1](https://vkvideo.ru/video-202243462_456239065)
- [Подготовка отчета](https://vkvideo.ru/video-202243462_456239067)
- [Подготовка презентации](https://vkvideo.ru/video-202243462_456239068)
- [Защита презентации](https://vkvideo.ru/video-202243462_456239066)

## Воспроизведение

Минимальный сценарий запуска:

```bash
cd ~/labs/lab01/project
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.instantiate()'
~/.juliaup/bin/julia --project=. -e 'include("scripts/growth.jl")'
~/.juliaup/bin/julia --project=. -e 'include("scripts/growth_parameters.jl")'
~/.juliaup/bin/julia --project=. scripts/tangle.jl
```
