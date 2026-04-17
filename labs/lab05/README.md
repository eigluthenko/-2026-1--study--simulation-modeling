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

## Состав лабораторной работы

- `project/` — Julia-проект с моделью сети Петри, скриптами, CSV-таблицами, графиками и literate-форматами.
- `report/` — исходник отчёта Quarto и собранные PDF/DOCX.
- `presentation/` — исходник презентации Quarto, PDF/HTML/PPTX и текст для защиты.

## Основные результаты

- Классическая сеть Петри для задачи обедающих философов приходит к `deadlock`.
- Сеть с позицией `Arbiter` предотвращает тупиковую конфигурацию.
- В параметрическом исследовании `classic` имеет `deadlock_rate = 1.0`, а `arbiter` — `deadlock_rate = 0.0`.
