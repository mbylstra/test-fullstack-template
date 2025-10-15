# Flutter Template

## How To use this template

### Set up the repo

Create a new project on github
git clone git@github.com:mbylstra/flutter-template.git your-project-name
git remote remove origin
git remote add origin git@github.com:mbylstra/your-project-name.git
git push

### Replace project names

cd scripts
./customize-template.sh

### Install packages

(from root)
flutter pub get
cd widgetbook && flutter pub get

### Prompt AI

To spin off a new project, write this prompt with thinking on (replacing new_project_name and prefix with your desired names):

This is currently a template. I want to spin off a new project named Grouseries. Create a new
firebase project with firebase mcp named {new_project_name} (or {prefix}-{new_project_name} grouseries if that name is not available). Update any files with the new name and remove any referencies to the flutter-template firebase project.

Make sure to set up Firebase Authentication for Web, Android and iOS. Tell me if I need to configure anything manually from the firebase website. I will tell you once I have done that and then you can continue configuring things. Make sure to fetch the latest google-services.json using firebase mcp.

Create a new firestore database using Firebase MCP.

AI is not exactly thorough so after that you will probably need to prompt:

There are still lots of references to the flutter template. Do a proper search.
