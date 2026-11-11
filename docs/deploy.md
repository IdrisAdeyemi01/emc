# Deploying EMC Portal (GitHub Pages)

Live site: **https://idrisadeyemi01.github.io/emc/** (repo `IdrisAdeyemi01/emc`).

Every push to `main` runs `.github/workflows/deploy.yml`. The workflow:

1. runs `dart analyze` and the tests
2. runs `jaspr build` with the two secrets below
3. publishes `apps/emc_web/build/jaspr` to Pages.

## One-time setup

1. **Pages source.** In the repo, go to Settings → Pages → Build and deployment → Source and choose **GitHub Actions**.
2. **Secrets.** Go to Settings → Secrets and variables → Actions → New repository secret, and add:
   - `EMC_API_URL`: the Apps Script web app URL (the `/exec` link from `backend/apps_script/README.md`).
   - `EMC_API_KEY`: the same key that's in the script's Script Properties.

   If either secret is missing, the site still deploys but shows "This site isn't set up yet".
3. **First deploy.** Go to Actions → Deploy to GitHub Pages → Run workflow, or push to `main`. When it finishes, the run page links to the site.

## How the path works

- `apps/emc_web/web/index.html` has `<base href="/">`, which keeps local `jaspr serve` working at the root.
- The workflow rewrites it to `/<repo name>/`. The router and every relative asset URL follow it.
- If the repo is renamed, the path follows automatically.
- If the site moves to a user/organization site (a repo named `<owner>.github.io`, served at `/`), set `BASE_PATH: /` in the workflow.

GitHub Pages has no rewrites for single-page apps. The workflow copies `index.html` to `404.html`, so opening or refreshing `/emc/reminders` still loads the app. The browser shows a 404 status for that first request; that's expected.

## Changing the key

1. Change it in Script Properties (see the backend README).
2. Update the `EMC_API_KEY` secret.
3. Re-run the workflow.

The old key keeps working on the live site until the new build is published.

## Privacy note

The key ships inside the public JavaScript, so anyone who opens the site can load the teacher list. This is light protection against casual discovery, not real login (CLAUDE.md 2.7). Real admin login is a later feature.
