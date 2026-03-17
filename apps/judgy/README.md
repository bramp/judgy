# Judgy

Apples to Apples inspired game.

## Project Setup

If you need to recreate the native platform folders (Android, iOS, macOS, web, etc.) to fix project references, follow these steps:

1. Delete the existing native directories (excluding `web` to preserve custom files like `privacy.html`) and recreate them using `flutter create`:
   ```bash
   rm -rf android macos ios windows linux
   flutter create --org net.bramp --project-name judgy .
   ```

2. Re-download Firebase configurations using the FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

3. Recreate the native splash screens so that deleted splash images are restored:
   ```bash
   dart run flutter_native_splash:create
   ```

## Firebase AI Logic (Prompt Templates)

The bot logic utilizes Firebase AI Logic. The prompts defining the bots' personalities are deployed as **Server Prompt Templates** locally in the `prompt_templates/` directory.

Since Firebase's AI Logic is currently in preview, the Firebase CLI doesn't yet have native commands to wrap these deployments (`firebase deploy --only templates` is not yet a thing).

### How to push templates:

**Option 1: Deploy manually via console (Recommended)**
1. Navigate to your Firebase project console.
2. Go to **Build -> AI Logic -> Prompt Templates**.
3. Create new templates named `bot-select-noun` and `bot-judge`.
4. Copy the contents of the `.yaml` files in `prompt_templates/` into the editor.

**Option 2: Use the REST API helper script**
If you have the `gcloud` CLI installed and authenticated to your project:
```bash
cd apps/judgy
./scripts/push_prompt_templates.sh
```
*Note: Because the API is in preview, the REST API payload requirements might change. Using the Console UI is currently the most stable approach.*
