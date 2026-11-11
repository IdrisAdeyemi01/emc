# EMC backend (Google Apps Script)

A read-only web app that returns the `Teachers' Contacts` tab as JSON for the EMC Portal (contract v1 in `CLAUDE.md` section 2.7). It runs as the sheet owner, so the spreadsheet itself can be private.

Files:
- `Code.gs`: the web app (`doGet`) and a `testContacts` helper.
- `appsscript.json`: manifest (Lagos timezone, read access to this one spreadsheet only, web app settings).

## First deploy (about 10 minutes)

### 1. Open the script editor from the sheet
1. Open the EMC spreadsheet in Google Sheets (signed in as the sheet owner).
2. **Extensions → Apps Script.** A new tab opens with a project bound to this spreadsheet.
3. Rename the project (top left, "Untitled project") to **EMC Portal backend**.

### 2. Paste the manifest
1. Click the **gear icon (Project Settings)** on the left.
2. Tick **Show "appsscript.json" manifest file in editor**.
3. Go back to the **Editor** (`< >` icon). Open `appsscript.json`, select everything, and replace it with the contents of this folder's `appsscript.json`.
4. Save (Ctrl/Cmd + S).

### 3. Paste the code
1. Open `Code.gs` in the editor, select everything, and replace it with this folder's `Code.gs`.
2. Save.

### 4. Create the API key
1. On your computer, in a terminal, run:
   ```bash
   openssl rand -hex 24
   ```
   Copy the 48-character result. This is `EMC_API_KEY`.
2. In Apps Script: **Project Settings → Script Properties → Add script property.**
   - Property: `EMC_API_KEY`
   - Value: the key you just generated
3. **Save script properties.**

### 5. Grant access and check the tab is readable
1. Back in the **Editor**, choose `testContacts` in the function dropdown at the top, then **Run**.
2. Google asks you to authorize: **Review permissions →** pick the owner account. If you see "Google hasn't verified this app", click **Advanced → Go to EMC Portal backend (unsafe)**. This is your own script; it only asks to view and manage *this* spreadsheet.
3. Open **Execution log**. You should see:
   ```
   Headers: Day | Class | Subject | Teacher | Phone numbers | Start Time
   Data rows: <a number>
   EMC_API_KEY set: yes
   ```
   If you see `Problem: sheet_not_found`, the tab isn't named exactly `Teachers' Contacts` (straight apostrophe).

### 6. Deploy as a web app
1. **Deploy → New deployment.**
2. Click the gear next to "Select type" → **Web app**.
3. Description: `v1`.
4. **Execute as: Me** (the sheet owner).
5. **Who has access: Anyone.** (Needed so the website can call it without a Google login. The API key is what protects it.)
6. **Deploy**, then copy the **Web app URL**. It looks like `https://script.google.com/macros/s/AKfy…/exec`.

### 7. Quick check in your browser
Replace `URL` and `KEY` with yours:
- `URL?action=contacts&key=wrong` → `{"ok":false,"error":"unauthorized"}`
- `URL?action=contacts&key=KEY` → `{"ok":true,…}` with the sheet's rows

### 8. Give the app the URL and key
In the repo root:
```bash
cp .env.example .env.local
```
Edit `.env.local` (it's git-ignored, never commit it):
```
EMC_API_URL=https://script.google.com/macros/s/AKfy…/exec
EMC_API_KEY=<the key from step 4>
```

### 9. Make the spreadsheet private (after the app works)
Once the portal loads data, in Google Sheets: **Share → General access → Restricted.** The app keeps working because the script reads the sheet as you.

## Updating the code later
Saving in the editor does **not** change the live web app.
1. Paste the new code and save.
2. **Deploy → Manage deployments →** pencil icon on the existing deployment → **Version: New version → Deploy.**

This keeps the same URL, so nothing else needs changing. (A *New deployment* would create a new URL.)

## Rotating the key
1. Generate a new key (step 4) and replace `EMC_API_KEY` in Script Properties. It takes effect immediately, no redeploy needed.
2. Update `.env.local` and the `EMC_API_KEY` GitHub Actions secret (M5), then rebuild the site.

## Using clasp instead (optional)
```bash
npm install -g @google/clasp && clasp login
cd backend/apps_script
clasp clone <scriptId> --rootDir .   # scriptId: Project Settings → IDs
clasp push && clasp deploy -i <deploymentId>
```
`.clasp.json` contains the script id; don't commit it.

## Notes
- The key ships inside the website's public JavaScript, so it's light protection against casual discovery, not real authentication (CLAUDE.md 2.7).
- The script never logs phone numbers or row contents. `testContacts` logs only header names and a row count.
