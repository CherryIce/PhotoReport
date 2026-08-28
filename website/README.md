# PhotoReport website

Dependency-free static website for 现场照片记录 / Site Photo Log.

## Files

- `index.html`: bilingual product website
- `privacy.html`: bilingual privacy policy
- `styles.css`: shared responsive and print styles
- `site.js`: language preference, language-aware links, and mobile navigation
- `assets/app-icon.png`: web copy of the current iOS marketing icon
- `assets/og.png`: social preview card

## Local preview

Serve this directory with any static HTTP server and open `index.html`.
Opening the HTML files directly also works, but an HTTP preview more closely
matches production hosting.

## Required before publishing

1. Replace every Chinese and English operator/contact placeholder in
   `index.html` and `privacy.html` with confirmed public details.
2. Keep section 7's neutral network-log disclosure; no hosting provider name is
   required.
3. Use absolute production URLs for Open Graph images after the final domain is
   known.
4. Recheck the policy whenever app permissions, SDKs, storage, export, sync,
   account, or analytics behavior changes.
5. Have the final policy reviewed for the countries and regions where the app
   will be distributed. This repository draft is product-specific compliance
   content, not legal advice.
