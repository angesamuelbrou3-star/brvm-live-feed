# BRVM Live Feed

Automated BRVM market quotes feed powered by R, GitHub Actions and the `BRVM` R package.

## Files

- `quotes.json`: public JSON feed consumed by dashboards.
- `scripts/fetch_brvm.R`: fetches, normalizes and validates BRVM quotes.
- `.github/workflows/update-quotes.yml`: scheduled weekday update and manual run.

## Feed URL

Raw JSON: `https://raw.githubusercontent.com/angesamuelbrou3-star/brvm-live-feed/main/quotes.json`

## Automation

The workflow runs Monday to Friday at 16:30 UTC and can also be launched manually from **Actions → Update BRVM quotes → Run workflow**.

## Data format

The JSON contains `source`, `isSeed`, `currency`, `updatedAt`, `count`, `quotes` and `dailyChangePct`. Prices are in XOF. A seed file is provided until the first successful workflow run.

## Disclaimer

For informational and educational use only. Verify data with official BRVM sources before investment decisions.