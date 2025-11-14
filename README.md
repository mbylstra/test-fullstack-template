# Flutter Template 

## How To use this template

### Set up the repo

Create a new project on github
```
git clone git@github.com:mbylstra/flutter-template.git your-project-name
cd your-project-name
git remote remove origin
git remote add origin git@github.com:mbylstra/your-project-name.git
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

### Quick test
Connect phone with cable
```
make flutter-run
```
Just check if it compiles and runs

### Set up Claude

copy .envrc.example to .envrc and fill in the values
start claude (shouldn't be any warnings)

### Prompt AI

### Step 1

```
This is repo that was cloned from a Template. The existing config files are from the template. We must create new Firebase entities for our new project.

Create a new firebase project using firebase mcp named mb-meal-chooser

Make sure to set up Firebase Authentication for Web, Android and iOS. This project will use Google Authentication (sign in with Google button) Tell me if I need to configure anything manually from the firebase website. I will tell you once I have done that and then you can continue configuring things. Make sure to fetch the latest google-services.json or any other files that need replacing using firebase mcp.

Create a new firestore database using Firebase MCP. Do not change the existing firestore.rules and firestore.index.json from the templateThis is repo that was cloned from a Template. The existing config files are from the template. We must create new Firebase entities for our new project.

Make sure to set up Firebase Authentication for Web, Android and iOS. This project will use Google Authentication (sign in with Google button) Tell me if I need to configure anything manually from the firebase website. I will tell you once I have done that and then you can continue configuring things. Make sure to fetch the latest google-services.json or any other files that need replacing using firebase mcp.

Create a new firestore database using Firebase MCP. Do not change the existing firestore.rules and firestore.index.json from the template.
```

AI should give you a link to a web page where you need to "get started" with authentication, then enable Google authentication, then click enable button and enter your support email.

### Step 2

Then give this prompt:

```
I got this message after enabling Google auth:

Download the latest configuration file
Enabling Google sign-in for the first time creates new OAuth clients, which are automatically added to the config files for your apps.
Download and replace the configuration files in your apps so that you can use Google sign-in for your apps.
After replacing your config files, finish setting up Google sign-in for Android and Apple apps.

For the android app: Provide SHA-1 fingerprint, and then download and replace the configuration file in your app. Go to Project settings > Your apps section.
For the iOS app: download GoogleService-Info.plist

Do this stuff using firebase mcp.
```

### Test

- Run the app with `make flutter-run`
- Sign in
- Go to the notes screen. Try adding a note. Check in the firebase web console whether it's correctly adding the note to the correct firebase project. You might see "index is currently being built" in which case you'll need to wait a little while first.

