# Имитационное моделирование
Глущенко Евгений Игоревич
2026-05-29

# Информация

## Докладчик и работа

<div class="columns" align="center">

<div class="column" width="67%">

- Глущенко Евгений Игоревич
- студент группы НФИбд-01-23
- студенческий билет: 1132239110
- РУДН имени Патриса Лумумбы
- тема: подготовка стенда и модель экспоненциального роста
- средства: Julia, DrWatson, CairoMakie, Literate.jl, git

</div>

<div class="column" width="30%">

<img src="_resources/image/logo_rudn.png" style="width:72.0%" />

</div>

</div>

# Цель и задачи

## Цель и постановка

- Освоить инструменты программной инженерии: git, семантическое
  версионирование, общепринятые коммиты
- Подготовить рабочее пространство курса
- Познакомиться с Julia и DrWatson
- Реализовать модель экспоненциального роста в литературном стиле
- Сгенерировать производные форматы и провести параметрическое
  исследование

## Что требовалось сделать

1.  Настроить git, ssh- и gpg-ключи
2.  Установить Julia и пакеты
3.  Реализовать модель `du/dt = α·u`
4.  Преобразовать код в литературный стиль
5.  Сгенерировать `clean`, `markdown`, `ipynb` и добавить
    параметрическое исследование

# Теоретическая часть

## Программная инженерия

<div class="columns">

<div class="column" width="50%">

Семантическое версионирование:

- формат `МАЖОРНАЯ.МИНОРНАЯ.ПАТЧ`
- MAJOR — несовместимые изменения
- MINOR — новая функциональность
- PATCH — исправления

</div>

<div class="column" width="50%">

Общепринятые коммиты:

- `<тип>(<область>): <описание>`
- `feat` → MINOR, `fix` → PATCH
- `BREAKING CHANGE` → MAJOR
- также `docs`, `refactor`, `test`, `ci`

</div>

</div>

## Модель экспоненциального роста

<div class="columns">

<div class="column" width="50%">

$$\frac{du}{dt} = \alpha u, \quad u(0) = u_0$$

Аналитическое решение:

$$u(t) = u_0 e^{\alpha t}$$

</div>

<div class="column" width="50%">

Время удвоения:

$$T_2 = \frac{\ln 2}{\alpha}$$

При `α > 0` — рост, при `α < 0` — затухание. Применение: биология,
финансы, эпидемиология.

</div>

</div>

## Литературное программирование

- Код и описание объединены в одном источнике `*_literate.jl`
- `Literate.jl` порождает из него:
  - чистый скрипт (`clean`)
  - markdown-документ
  - исполняемый Jupyter notebook
- Проект организован на `DrWatson.jl`, расчёты на Julia

# Реализация

## Подготовка стенда

``` bash
git config --global user.name "Name Surname"
git config --global user.email "work@mail"
git config --global init.defaultBranch master
git config --global core.autocrlf input

ssh-keygen -t ed25519 -C "Name Surname"
gpg --full-generate-key
```

## Реализация модели

``` julia
analytic_growth(u0, α, t) = u0 * exp(α * t)
doubling_time(α) = log(2) / α

function run_growth(u0, α, tspan; dt = 0.1)
    u = Float64(u0)
    for step in 1:nsteps          # метод Рунге–Кутты 4
        k1 = α * u
        k2 = α * (u + dt/2 * k1)
        k3 = α * (u + dt/2 * k2)
        k4 = α * (u + dt * k3)
        u = u + dt/6 * (k1 + 2k2 + 2k3 + k4)
    end
end
```

# Результаты

## Инициализация и базовый запуск

<div class="columns">

<div class="column" width="50%">

<img src="image/screenshots/fig02-instantiate.png" style="width:100.0%"
alt="Активация окружения" />

</div>

<div class="column" width="50%">

<img src="image/screenshots/fig03-growth.png" style="width:100.0%"
alt="Запуск scripts/growth.jl" />

</div>

</div>

## Базовый эксперимент (α = 0.3)

<div class="columns">

<div class="column" width="50%">

Параметры:

- `u0 = 1.0`, `α = 0.3`
- `t ∈ [0, 10]`, `dt = 0.1`

Результаты:

- `u(10) = 20.0855 = e³`
- время удвоения `T₂ = 2.31`
- погрешность RK4 `≈ 4·10⁻⁷`

</div>

<div class="column" width="50%">

<img src="image/generated/growth_base.png" style="width:100.0%"
alt="Рост при α = 0.3" />

</div>

</div>

## Параметрическое исследование

Сетка `α ∈ {0.1, 0.3, 0.5, 0.8, 1.0}`:

| `α` | `u(10)` | `T₂ = ln2/α` |
|----:|--------:|-------------:|
| 0.1 |    2.72 |         6.93 |
| 0.3 |   20.09 |         2.31 |
| 0.5 |   148.4 |         1.39 |
| 0.8 |    2981 |         0.87 |
| 1.0 |   22026 |         0.69 |

С ростом `α` рост ускоряется, а время удвоения убывает.

## Запуск параметрического исследования

<img src="image/screenshots/fig04-growth-params.png" style="width:92.0%"
alt="Запуск scripts/growth_parameters.jl — 5 сценариев" />

## Сравнение траекторий и время удвоения

<div class="columns">

<div class="column" width="50%">

<img src="image/generated/growth_comparison.png" style="width:100.0%"
alt="Траектории по α" />

</div>

<div class="column" width="50%">

<img src="image/generated/growth_doubling.png" style="width:100.0%"
alt="Время удвоения" />

</div>

</div>

Имитационные точки ложатся на теоретическую кривую `T₂ = ln2/α`.

# Воспроизводимость

## Literate-артефакты

- Единый источник `*_literate.jl` через `Literate.jl` порождает чистый
  скрипт, markdown и исполняемый ноутбук
- Генерация одним сценарием `scripts/tangle.jl`
- Notebook-файлы выполняются при генерации

``` text
generated for growth
generated for growth_parameters
```

## Генерация и проверка артефактов

<div class="columns">

<div class="column" width="55%">

<img src="image/screenshots/fig05-tangle.png" style="width:100.0%"
alt="Запуск scripts/tangle.jl" />

</div>

<div class="column" width="45%">

<img src="image/screenshots/fig06-check-files.png" style="width:88.0%"
alt="Проверка каталогов результатов" />

</div>

</div>

## Выводы

- Освоены git, семантическое версионирование, общепринятые коммиты, ssh
  и gpg
- Реализована модель `du/dt = α·u` методом Рунге–Кутты 4-го порядка
- Численное решение совпало с аналитикой `u(t) = u₀e^{αt}` с
  погрешностью `≈ 10⁻⁷`
- Параметрическое исследование подтвердило закон `T₂ = ln2/α`
- Проект оформлен воспроизводимо с помощью `DrWatson` и `Literate`
