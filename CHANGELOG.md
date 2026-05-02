# Changelog

## 1.5.0 (2026-05-01)

### Features

* **lab06:** модель SIR в подходе сетей Петри ([lab06](labs/lab06/))
  - Добавлен Julia-проект `project` как обычная директория основного репозитория, без вложенного Git-репозитория и без сабмодуля
  - Реализован модуль `SIRPetri.jl` с построением сети Петри, детерминированной RK4-симуляцией и стохастической симуляцией методом Гиллеспи
  - Подготовлены сценарии базового прогона, сканирования параметра `beta`, построения GIF-анимации и итогового сравнения результатов
  - Сгенерированы воспроизводимые артефакты: CSV-таблицы, PNG-графики, GIF-анимация, Quarto-документы и Jupyter notebooks
  - Обновлены отчет и презентация Quarto, добавлены собранные PDF/DOCX/PPTX/HTML-версии и Markdown-файлы для релиза
  - Добавлены ссылки VK Видео и RuTube на выполнение, анимацию, защиту, отчет, презентацию и плейлисты

## [v1.0.5] - 2026-04-18

### Added

- Added laboratory work 5: Petri nets and the dining philosophers problem.
- Added Julia project sources, CSV data, plots, GIF animation, Quarto report, and Quarto presentation.
- Added VK Video and RuTube links for lab05.

### Changed

- Cleaned lab05 release files by removing local command and speech helper files from the repository.

## [v1.0.4] - 2026-04-06

### Added

- Added laboratory work 4 materials, report, presentation, data, plots, and video resource links.

## [v1.0.2] - 2026-03-22

### Added

- Added laboratory work 3 materials and release references.

## [v1.0.1] - 2026-03-14

### Added

- Added early course laboratory materials and repository structure updates.

## [v1.0.0] - 2026-03-06


### Features

* **main:** make course structure ([6657be5](https://github.com/eigluthenko/-2026-1--study--simulation-modeling/commits/6657be5e0114cc8be4e7fad97da0dd1f681ecb24))
