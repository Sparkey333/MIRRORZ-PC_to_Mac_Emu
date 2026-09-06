# MIRRORZ website

Static marketing, pricing, compatibility, comparison and docs site. No dependencies.

```bash
node website/build.mjs   # → website/dist/
```

Inputs: `pricing/pricing.json` (prices), `server/src/compat/seed.json` (compatibility catalog), `website/content/compare.json` (verified competitor facts, sourced from `docs/research`), `website/content/faq.json`, and `store/legal/*.md` (rendered when present). Deploy `dist/` to any static host; `sitemap.xml` and `robots.txt` are generated.
