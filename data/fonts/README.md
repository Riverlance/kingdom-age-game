IMPORTANT: italic usually conflicts with regular/bold.

The best way is to use:
  * Font for: [regular] + [bold]
  * Font for: [italic] + [bold-italic]

---

Option 1:

https://yabe-webfont.jooo.si/docs/misc/static-fonts-to-variable

---

Option 2:

https://blode.co/static-to-variable
https://static-to-variable.blode.md/quickstart

CMD:
```
npm install -g static-to-variable
winget install --id=astral-sh.uv -e
uv --version

cd ~/Downloads/Inter/static # folder with font files
static-to-variable init
static-to-variable build
```

PowerShell:
```
npm.cmd install -g static-to-variable
winget install --id=astral-sh.uv -e
uv --version

cd ~/Downloads/Inter/static # folder with font files
static-to-variable.cmd init
static-to-variable.cmd build
```
