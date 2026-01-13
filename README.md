# Fullstack Template

## Follow these steps to get started

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

## Maintenance

To keep in sync with the latest version of the template, do either:

(if there have only been minor changes, and unlikely to have many conflicts)

```
make rebase-from-latest-template
```

(if there have been major changes)

```
make merge-latest-template
```

This might be a little or a huge amount of work depending on how behind it is.

## How many projects will fit on the one VM?

They seem to use roughly 150MB per project. So, if you have a 512MB Instance, you should be able to get away with three projects.

Start and stop backends to save memory/CPU:

`make stop-server-services`
`make start-server-services`
