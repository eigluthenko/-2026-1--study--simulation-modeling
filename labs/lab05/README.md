# Лабораторная работа №5: Аппарат сетей Петри

## Репозитории

### GitHub

- [Основной репозиторий](https://github.com/eigluthenko/-2026-1--study--simulation-modeling)
- [Папка лабораторной работы №5](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/tree/master/labs/lab05)
- [Релиз lab05](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/releases/tag/v1.0.5)
- [CHANGELOG](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/blob/master/CHANGELOG.md)

### GitVerse

- [Основной репозиторий](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling)
- [Папка лабораторной работы №5](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/labs/lab05)
- [Релиз lab05](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/releases/tag/v1.0.5)
- [CHANGELOG](https://gitverse.ru/eiglushchenko/2026-1--study--simulation-modeling/content/master/CHANGELOG.md)

## Видео на RuTube

- [Плейлист лабораторной работы №5](https://rutube.ru/plst/1592906/)
- [Выполнение лабораторной работы 5](https://rutube.ru/video/65529b3d6adf586aeab5462211aa7dcb/)
- [Составление отчёта](https://rutube.ru/video/48d734bda80af4a3493e716bf3817419/)
- [Составление презентации](https://rutube.ru/video/e23279dbe6e055541b9d9ba747002a03/)
- [Защита: презентация](https://rutube.ru/video/0c3974fde87efd8e957a3b0acb6867ee/)

## Видео на VK Video

- [Плейлист лабораторной работы №5](https://vkvideo.ru/playlist/-202243462_4)
- [Выполнение лабораторной работы 5](https://vkvideo.ru/playlist/-202243462_4)
- [Составление отчёта](https://vkvideo.ru/playlist/-202243462_4)
- [Составление презентации](https://vkvideo.ru/playlist/-202243462_4)
- [Защита: презентация](https://vkvideo.ru/playlist/-202243462_4)

## Состав лабораторной работы

- `project/` — Julia-проект с моделью сети Петри, скриптами, CSV-таблицами, графиками и literate-форматами.
- `report/` — исходник отчёта Quarto и собранные PDF/DOCX.
- `presentation/` — исходник презентации Quarto и собранные PDF/HTML/PPTX.

## Основные результаты

- Классическая сеть Петри для задачи обедающих философов приходит к `deadlock`.
- Сеть с позицией `Arbiter` предотвращает тупиковую конфигурацию.
- В параметрическом исследовании `classic` имеет `deadlock_rate = 1.0`, а `arbiter` — `deadlock_rate = 0.0`.
