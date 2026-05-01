# Лабораторная работа №6: Реализация модели SIR в подходе сетей Петри

## Репозитории

### GitHub

- [Основной репозиторий](https://github.com/eigluthenko/-2026-1--study--simulation-modeling)
- [Папка лабораторной работы №6](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/tree/master/labs/lab06)
- [Релиз lab06](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/releases/tag/v1.0.6)
- [CHANGELOG](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/blob/master/CHANGELOG.md)

### GitVerse

- [Основной репозиторий](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling)
- [Папка лабораторной работы №6](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/labs/lab06)
- [Релиз lab06](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/releases/tag/v1.0.6)
- [CHANGELOG](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/CHANGELOG.md)

## Видео на VK Video

- [Плейлист лабораторной работы №6](https://vkvideo.ru/video-202243462_456239056?pl=-202243462_5)
- [Анимация SIR в сети Петри](https://vkvideo.ru/video-202243462_456239052)
- [Выполнение лабораторной работы 6](https://vkvideo.ru/video-202243462_456239053)
- [Защита лабораторной работы 6](https://vkvideo.ru/video-202243462_456239054)
- [Составление отчёта](https://vkvideo.ru/video-202243462_456239055)
- [Составление презентации](https://vkvideo.ru/video-202243462_456239056)

## Видео на RuTube

- [Плейлист лабораторной работы №6](https://rutube.ru/plst/1614608)
- [Анимация SIR в сети Петри](https://rutube.ru/video/07d9ca5f8718c21488a08f7e1dc25a7f/)
- [Выполнение лабораторной работы 6](https://rutube.ru/video/a3657068f634d53e96f136500ccbfaa3/)
- [Защита лабораторной работы 6](https://rutube.ru/video/dc3aeba4a86a38fc94da4eb32afda05f/)
- [Составление отчёта](https://rutube.ru/video/4af94b7eb06ad7f95f472c0e6a5b46b4/)
- [Составление презентации](https://rutube.ru/video/45e96e16aef9796972ffff6d2c307a4b/)

## Состав лабораторной работы

- `project/` — Julia-проект с моделью SIR в сети Петри, скриптами, CSV-таблицами, графиками, GIF-анимацией и literate-форматами.
- `report/` — исходник отчёта Quarto и собранные PDF/DOCX.
- `presentation/` — исходник презентации Quarto и собранные PDF/HTML/PPTX.

## Основные результаты

- Модель SIR описана сетью Петри с позициями `S`, `I`, `R` и переходами `infection`, `recovery`.
- Реализованы детерминированная симуляция методом Рунге-Кутты и стохастическая симуляция методом Гиллеспи.
- При `beta = 0.3`, `gamma = 0.1` детерминированный пик `I` равен `952.691`, стохастический пик `I` равен `999`.
- Параметрическое исследование по `beta` показало, что во всех проверенных случаях финальное число выздоровевших близко к `1000`.
