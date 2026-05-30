# Лабораторная работа №8: Реализация модели SIR в дискретно-событийном подходе

## Репозитории

### GitHub

- [Основной репозиторий](https://github.com/eigluthenko/-2026-1--study--simulation-modeling)
- [Папка лабораторной работы №8](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/tree/master/labs/lab08)
- [Релиз lab08](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/releases/tag/v1.0.8)
- [CHANGELOG](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/blob/master/CHANGELOG.md)

### GitVerse

- [Основной репозиторий](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling)
- [Папка лабораторной работы №8](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/labs/lab08)
- [Релиз lab08](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/releases/tag/v1.0.8)
- [CHANGELOG](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/CHANGELOG.md)

## Состав лабораторной работы

- `project/` — Julia-проект с дискретно-событийной моделью SIR на `ConcurrentSim`, детерминированной ОДУ-версией, скриптами, CSV-таблицами, графиками, markdown-документами и notebook-файлами;
- `report/` — исходник отчёта Quarto и собранные PDF/DOCX;
- `presentation/` — исходник презентации Quarto и собранные PDF/HTML/PPTX.

## Основные результаты

- базовый сценарий при `β = 0.05`, `c = 10`, `γ = 0.25` (`R0 = 2.0`) даёт пик `152` инфицированных в момент `t ≈ 18.4` и итоговую долю переболевших `0.759` при аналитической оценке конечного размера `0.797`;
- детерминированное решение системы ОДУ (пик `158`, доля `0.776`) согласуется с имитацией в пределах стохастического разброса;
- ансамбль из `24` независимых прогонов показал среднюю высоту пика `172` и разброс `133…217` без ранних затуханий;
- анализ чувствительности на сетке из `27` наборов параметров выявил пороговое поведение по `R0`: при `R0 ≤ 1` эпидемия затухает, при `R0 > 1` её масштаб монотонно растёт;
- выполнена оценка производительности до `10000` агентов (около `5.6` с на прогон);
- сформированы CSV-таблицы, `8` графиков PNG, два `markdown`-документа и два исполняемых `ipynb`-ноутбука;
- подготовлены полный отчёт Quarto и презентация Quarto.

## Видео

### RuTube

- [Плейлист лабораторной работы №8](https://rutube.ru/plst/1655770)
- [Выполнение лабораторной работы №8](https://rutube.ru/video/e22f2266443ed0c5577a0a684ce5a7f8/)
- [Подготовка отчета](https://rutube.ru/video/5b9296abb063142d8280b54bf13aed4b/)
- [Подготовка презентации](https://rutube.ru/video/f89a2debad0f091368314b5f1331143e/)
- [Защита презентации](https://rutube.ru/video/32321529874d7c4b5e6620755d125ec8/)

### VK Video

- [Плейлист лабораторной работы №8](https://vkvideo.ru/video-202243462_456239064?pl=-202243462_7)
- [Выполнение лабораторной работы №8](https://vkvideo.ru/video-202243462_456239061)
- [Подготовка отчета](https://vkvideo.ru/video-202243462_456239063)
- [Подготовка презентации](https://vkvideo.ru/video-202243462_456239064)
- [Защита презентации](https://vkvideo.ru/video-202243462_456239062)

## Воспроизведение

Минимальный сценарий запуска:

```bash
cd ~/labs/lab08/project
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.instantiate()'
~/.juliaup/bin/julia --project=. -e 'include("scripts/sir.jl")'
~/.juliaup/bin/julia --project=. -e 'include("scripts/sir_parameters.jl")'
~/.juliaup/bin/julia --project=. scripts/tangle.jl
```
