# Пошаговый гайд: Лабораторная работа №1
## Что вводить и что скриншотить

---

## ЧАСТЬ 1. Настройка git и gh

### ШАГ 1. Установка git и gh
```bash
sudo apt install git gh -y
```
📸 **Скрин 1** — установка завершена

### ШАГ 2. Базовая настройка git
```bash
git config --global user.name "Имя Фамилия"
git config --global user.email "1132239110@rudn.ru"
git config --global core.quotepath false
git config --global init.defaultBranch master
git config --global core.safecrlf warn
git config --list
```
📸 **Скрин 2** — вывод git config --list (видны имя и email)

### ШАГ 3. Авторизация GitHub через gh
```bash
gh auth login
```
В меню выбираешь: GitHub.com → SSH → Generate new SSH key → Login with web browser
Вводишь одноразовый код в браузере, подтверждаешь.

```bash
gh config set -h github.com git_protocol ssh
```
📸 **Скрин 3** — успешная авторизация (Logged in as ...)

### ШАГ 4. Генерация SSH-ключа
```bash
ssh-keygen -t ed25519 -C "1132239110@rudn.ru"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```
📸 **Скрин 4** — публичный ключ (строка начинается с ssh-ed25519)

### ШАГ 5. Добавление SSH-ключа в Gitverse
- Копируешь содержимое `~/.ssh/id_ed25519.pub`
- Gitverse → Мой профиль → Ключи SSH → Создать ключ → вставляешь

📸 **Скрин 5** — ключ добавлен на Gitverse

### ШАГ 6. Генерация GPG-ключа
```bash
gpg --full-generate-key
```
В меню:
- Тип: `1` (RSA and RSA)
- Размер: `4096`
- Срок: `0` (бессрочный) → `y`
- Имя, Email: `1132239110@rudn.ru`

```bash
gpg --list-secret-keys --keyid-format long
```
📸 **Скрин 6** — вывод с ID ключа (длинная hex-строка)

### ШАГ 7. Добавление GPG-ключа в GitHub
```bash
gpg --armor --export ВАШ_ID_КЛЮЧА
```
Копируешь весь вывод → GitHub → Settings → SSH and GPG keys → New GPG key → вставляешь

📸 **Скрин 7** — GPG-ключ добавлен на GitHub

### ШАГ 8. Настройка подписи коммитов
```bash
git config --global user.signingkey ВАШ_ID_КЛЮЧА
git config --global commit.gpgsign true
git config --global gpg.program $(which gpg)
git config --list | grep sign
```
📸 **Скрин 8** — видны signingkey и gpgsign=true

---

## ЧАСТЬ 2. Создание рабочего пространства

### ШАГ 9. Создание каталога курса
```bash
mkdir -p ~/work/study/2026-1/2026-1==study--simulation-modeling/labs/lab01
ls ~/work/study/2026-1/
```
📸 **Скрин 9** — видна папка 2026-1==study--simulation-modeling

```bash
ls ~/work/study/2026-1/2026-1==study--simulation-modeling/labs/
```
📸 **Скрин 10** — видна папка lab01

### ШАГ 10. Создание DrWatson проекта
```bash
cd ~/work/study/2026-1/2026-1==study--simulation-modeling/labs/lab01
julia
```

В Julia REPL:
```julia
using Pkg
Pkg.add("DrWatson")
```
📸 **Скрин 11** — строки Installing/Installed DrWatson

```julia
using DrWatson
initialize_project("project"; authors="Имя Фамилия", git=false)
exit()
```
📸 **Скрин 12** — вывод initialize_project + выход

```bash
ls project/
```
📸 **Скрин 13** — содержимое: Project.toml, src/, scripts/, data/, ...

### ШАГ 11. Установка пакетов
```bash
cat project/add_packages.jl
```
📸 **Скрин 14** — содержимое add_packages.jl

```bash
julia --project=project project/add_packages.jl
```
📸 **Скрин 15** — начало установки (Installing...)
📸 **Скрин 16** — конец: `✓ Все пакеты установлены!`

---

## ЧАСТЬ 3. Литературный код — базовая модель

### ШАГ 12. Просмотр скрипта 01
```bash
cat project/scripts/01_exponential_growth.jl
```
📸 **Скрин 17** — содержимое 01_exponential_growth.jl

### ШАГ 13. Запуск скрипта 01
```bash
julia --project=project project/scripts/01_exponential_growth.jl
```
📸 **Скрин 18** — таблица DataFrame + `Аналитическое время удвоения: 2.31`

```bash
ls project/plots/01_exponential_growth/
```
📸 **Скрин 19** — файл exponential_growth_α=0.3.png

### ШАГ 14. Генерация форматов (tangle.jl)
```bash
cat project/scripts/tangle.jl
```
📸 **Скрин 20** — код tangle.jl

```bash
julia --project=project project/scripts/tangle.jl project/scripts/01_exponential_growth.jl
```
📸 **Скрин 21** — три строки ✓: чистый скрипт, Quarto, Notebook

```bash
ls project/notebooks/
ls project/markdown/
```
📸 **Скрин 22** — файлы 01_exponential_growth.ipynb и .qmd

### ШАГ 15. Выполнение Jupyter Notebook (01)
```bash
julia --project=project -e 'using IJulia; notebook(dir="project/notebooks")'
```
В браузере открываешь `01_exponential_growth.ipynb` → Run All

📸 **Скрин 23** — notebook с выполненными ячейками и графиком

---

## ЧАСТЬ 4. Параметрическая модель

### ШАГ 16. Просмотр скрипта 02
```bash
head -60 project/scripts/02_exponential_growth.jl
```
📸 **Скрин 24** — видны param_grid и base_params

### ШАГ 17. Запуск скрипта 02
```bash
julia --project=project project/scripts/02_exponential_growth.jl
```
📸 **Скрин 25** — секция ПАРАМЕТРИЧЕСКОЕ СКАНИРОВАНИЕ (прогресс)
📸 **Скрин 26** — секция ЛАБОРАТОРНАЯ РАБОТА ЗАВЕРШЕНА + таблица

```bash
ls project/plots/02_exponential_growth/
```
📸 **Скрин 27** — 4 файла .png

### ШАГ 18. Генерация форматов (02)
```bash
julia --project=project project/scripts/tangle.jl project/scripts/02_exponential_growth.jl
```
📸 **Скрин 28** — три строки ✓ для скрипта 02

### ШАГ 19. Выполнение Jupyter Notebook (02)
В уже открытом Jupyter → открываешь `02_exponential_growth.ipynb` → Run All

📸 **Скрин 29** — notebook 02 с параметрическими графиками

### ШАГ 20. Итоговая структура
```bash
find project -type f | grep -v ".jld2\|Manifest\|.git" | sort
```
📸 **Скрин 30** — все созданные файлы проекта

---

## ИТОГО: 30 скриншотов

### Именование файлов для отчёта:
```
fig-01-git-install.png
fig-02-git-config.png
fig-03-gh-auth.png
fig-04-ssh-key.png
fig-05-gitverse-key.png
fig-06-gpg-key.png
fig-07-github-gpg.png
fig-08-git-sign.png
fig-09-mkdir-course.png
fig-10-mkdir-lab.png
fig-11-drwatson-add.png
fig-12-initialize-project.png
fig-13-project-structure.png
fig-14-add-packages-code.png
fig-15-pkg-install-start.png
fig-16-pkg-install-done.png
fig-17-script01-code.png
fig-18-script01-run.png
fig-19-plots-01-list.png
fig-20-tangle-code.png
fig-21-tangle-01-output.png
fig-22-generated-files-01.png
fig-23-notebook-01.png
fig-24-script02-params.png
fig-25-script02-start.png
fig-26-script02-done.png
fig-27-plots-02-list.png
fig-28-tangle-02-output.png
fig-29-notebook-02.png
fig-30-final-structure.png
```
Кладёшь в папку `report/image/` и перекомпилируешь отчёт.
