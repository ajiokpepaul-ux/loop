# LOOP Campus MVP — Google-ready launch kit

This starter includes:
- Email/password sign-up and sign-in
- Google OAuth sign-in through Supabase Auth
- Student profile setup and editing
- Discover registered profiles
- Connection requests, accept/decline
- Messaging between accepted connections
- Block and report controls
- Supabase schema and row-level security policies

This is an MVP starter, not a fully audited production social network. Test with a small group before public launch. It does not yet include university identity verification, a moderator dashboard, account deletion UI, or realtime message updates.

## A. Supabase database setup
1. Open your Supabase project.
2. Go to **SQL Editor → New query**.
3. Paste the full contents of `schema.sql`, then click **Run**.
4. The website is already configured with the Supabase Project URL and publishable key supplied for this project. The publishable key is intended for browser use; never put a Supabase secret/service-role key in this website.

If you have already run the SQL successfully, you do not need to run it again just because Google sign-in was added.

## B. Confirm Google provider settings
1. In Supabase, open **Authentication → Sign In / Providers → Google** (the wording may vary).
2. Make sure Google is enabled and that the Google **Client ID** and **Client Secret** are saved there.
3. The **Authorized redirect URI** configured in Google Cloud must be the callback URL Supabase displays in its Google provider settings. It normally looks like:
   `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
4. Do not put the Google Client Secret in `index.html`.

## C. Set Supabase site and redirect URLs
1. In Supabase, open **Authentication → URL Configuration**.
2. Set **Site URL** to your deployed LOOP website URL, once you have it.
3. Add that exact website URL under **Redirect URLs**. For example, if the deployed website is `https://your-loop-site.vercel.app`, add that URL. Replace the example with your actual URL.
4. Save the settings.

Google OAuth needs LOOP to run from a website URL. Opening `index.html` directly as a `file://` page will not complete Google sign-in.

## D. Google Cloud configuration
In Google Auth Platform → Clients, open the Web application OAuth client:
- **Authorized JavaScript origins**: add the origin of the actual deployed LOOP site, e.g. `https://your-loop-site.vercel.app` (no path or trailing slash). Use your real domain, not this example.
- **Authorized redirect URIs**: paste the exact callback URI shown in Supabase's Google provider settings.
Save changes if you edit these values.

## E. Deploy online
1. Create a GitHub repository. Keep it private while testing.
2. Upload `index.html`, `schema.sql`, and `README.md` from this folder.
3. Import the repository into Vercel and deploy as a static site (no build command needed).
4. Copy the actual Vercel URL into Supabase **Authentication → URL Configuration** and Google Cloud **Authorized JavaScript origins**.
5. Test Google sign-in from the deployed URL, then test email sign-up, confirmation, profile creation, discovery, connection requests, and chat with two test accounts.

## Troubleshooting
- **Google redirects back with an error**: check that Google provider is enabled in Supabase, Client ID/Secret are correct, and Google's Authorized redirect URI exactly matches the callback shown by Supabase.
- **Redirect URL not allowed**: add the exact deployed LOOP URL to Supabase Authentication → URL Configuration → Redirect URLs.
- **Google button says to publish first**: open the site from its deployed HTTPS URL, not directly from a local file.
- **Email confirmation required**: use the confirmation link sent to the email before signing in.
- **Invalid login credentials**: verify the email and password, or create a new test account.
- **Database / RLS error**: inspect the SQL Editor output and browser message; do not disable RLS to bypass an error.
- **No profiles in Discover**: only users who have registered and saved profiles appear.

## Safety before public launch
- Start with a small invited test group.
- Add student verification and a trusted moderator workflow before presenting any account as campus-verified.
- Add account deletion, privacy notice, terms, spam/rate limits, and abuse response procedures before broad launch.
- Do not collect unnecessary personal information.
- Review current Supabase and Vercel plans and limits before launch.

Official guides:
- Supabase Google OAuth: https://supabase.com/docs/guides/auth/social-login/auth-google
- Supabase Auth URL configuration: https://supabase.com/docs/guides/auth/redirect-urls
- Supabase database security: https://supabase.com/docs/guides/database/secure-data
- Vercel deployments: https://vercel.com/docs/deployments/overview
