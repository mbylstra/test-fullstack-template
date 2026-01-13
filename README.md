# Fullstack Template

## Follow these steps

### Initialize the project

#### Set up the repo

Create a new project on github

```
git clone git@github.com:mbylstra/fllstck-tmplt.git {{your-project-name}}
cd your-project-name
git remote remove origin
git remote add origin git@github.com:mbylstra/{{your-project-name}}.git
git push
```

#### Enable tracking of the template repo

This is so we can merge/rebase changes to the template in the future

`make track-template-repo`

#### Replace project names

`make customize-template`

#### Set up .envrc

copy .envrc.example to .envrc and fill in the values

#### Test Claude

start claude (shouldn't be any warnings)

#### Install packages

```
make install
```

### Initialize the mobile app

#### Quick test

Connect phone (iphone or android) with cable

```
cd mobile-app
make flutter-run
```

### Configure Production Deployment and Deploy to Prod

```
cd scripts/automated-deployment
./setup-automated-deployment.sh
```
