# Fullstack Template

## How To use this template

### Set up the repo

Create a new project on github

```
git clone git@github.com:mbylstra/fullstack-template.git {{your-project-name}}
cd your-project-name
git remote remove origin
git remote add origin git@github.com:mbylstra/{{your-project-name}}.git
git push
```

### Enable tracking of the template repo

This is so we can merge/rebase changes to the template in the future

`make track-template-repo`

### Replace project names

`make customize-template`

### Install packages

(from root)

```
flutter pub get
cd widgetbook && flutter pub get
```

### Set up Claude

copy .envrc.example to .envrc and fill in the values
start claude (shouldn't be any warnings)

### Quick test

Connect phone (iphone or android) with cable

```
make flutter-run
```
