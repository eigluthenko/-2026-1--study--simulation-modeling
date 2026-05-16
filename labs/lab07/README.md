# Лабораторная работа №7: Дискретно-событийное моделирование

## Репозитории

### GitHub

- [Основной репозиторий](https://github.com/eigluthenko/-2026-1--study--simulation-modeling)
- [Папка лабораторной работы №7](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/tree/master/labs/lab07)
- [Релиз lab07](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/releases/tag/v1.0.7)
- [CHANGELOG](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/blob/master/CHANGELOG.md)

### GitVerse

- [Основной репозиторий](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling)
- [Папка лабораторной работы №7](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/labs/lab07)
- [Релиз lab07](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/releases/tag/v1.0.7)
- [CHANGELOG](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/CHANGELOG.md)

## Состав лабораторной работы

- `project/` — Julia-проект с моделями `M/M/c` и Росса, скриптами, CSV-таблицами, графиками, markdown-документами и notebook-файлами;
- `report/` — исходник отчета Quarto и собранные PDF/DOCX;
- `presentation/` — исходник презентации Quarto и собранные PDF/HTML/PPTX.

## Основные результаты

- для базового сценария `M/M/c` при `lambda = 0.9`, `mu = 0.5`, `c = 2` получено `sim_wq = 8.3449`, `sim_utilization = 0.8989`;
- для базового сценария модели Росса при `N = 10`, `S = 3`, `repairers = 1` получено среднее время до отказа `11937.8165`, аналитическое значение `12340.0`;
- выполнены параметрические исследования по числу каналов, интенсивности потока, числу рабочих машин, резервов и ремонтников;
- сформированы таблицы `CSV`, графики `PNG`, четыре `markdown`-файла и четыре исполняемых `ipynb`-ноутбука;
- подготовлены полный отчет Quarto и презентация Quarto со скриншотами выполнения лабораторной работы.

## Видео

### RuTube

- [Плейлист лабораторной работы №7](https://rutube.ru/plst/1635390)
- [Выполнение лабораторной работы №7](https://rutube.ru/video/18feb77e61743b70e8b1142c0d5caff5/)
- [Подготовка отчета](https://rutube.ru/video/eba4fb5da7fb355f92baf3b872229084/)
- [Подготовка презентации](https://rutube.ru/video/7d33be7ada2e2694c9bcc837c69cc5ca/)
- [Защита презентации](https://rutube.ru/video/35fc903f90521939074d004a4a523749/)

### VK Video

- [Плейлист лабораторной работы №7](https://vkvideo.ru/video-202243462_456239057?pl=-202243462_6)
- [Выполнение лабораторной работы №7](https://vkvideo.ru/video-202243462_456239058)
- [Подготовка отчета](https://vkvideo.ru/video-202243462_456239059)
- [Подготовка презентации](https://vkvideo.ru/video-202243462_456239060)
- [Защита презентации](https://vkvideo.ru/video-202243462_456239057)

## Воспроизведение

Минимальный сценарий запуска:

```bash
cd ~/labs/lab07/project
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.instantiate()'
~/.juliaup/bin/julia --project=. -e 'include("scripts/mmc.jl")'
~/.juliaup/bin/julia --project=. -e 'include("scripts/mmc_parameters.jl")'
~/.juliaup/bin/julia --project=. -e 'include("scripts/ross.jl")'
~/.juliaup/bin/julia --project=. -e 'include("scripts/ross_parameters.jl")'
~/.juliaup/bin/julia --project=. scripts/tangle.jl
```
