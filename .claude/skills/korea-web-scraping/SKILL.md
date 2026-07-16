---
name: korea-web-scraping
description: Scraping and OSINT collection from Korean (South Korea) websites — Naver, Daum, Kakao, Coupang, government open-data portals (data.go.kr), DART corporate filings, and similar. Use whenever the user wants to pull data from a `.kr` site, mentions Naver/Daum/Coupang/DART, hits mojibake with Korean text (EUC-KR/CP949), needs to handle Korean sites' heavier bot defenses, or asks for OSINT research on Korean individuals/companies/domains. Covers legal boundaries (PIPA), encoding, official APIs vs scraping, JS-rendered pages, and rate-limit-safe request patterns.
---

# Korean Web Scraping

Korean sites have a few recurring gotchas that don't show up when scraping US/EU sites: legacy encodings, aggressive bot detection on the big portals, and a stricter personal-data law. This skill covers what to check before writing a scraper and how to build one that behaves.

## 1. Check legality and terms first

Before scraping any Korean site:

- **PIPA (개인정보보호법)** is Korea's personal-data law and is stricter than GDPR in places — it treats resident registration numbers, names + contact info, and similar as protected regardless of whether the data is "public." Scraping personal data (real names, phone numbers, addresses, resident numbers) from Korean sites for anything beyond narrow, authorized research is a legal risk, not just a ToS issue. If the task involves individuals, ask the user what the data will be used for and whether they have a lawful basis, rather than assuming public-facing means fair game.
- Read `robots.txt` and the site's ToS. Naver, Daum, and Coupang all explicitly restrict automated collection in their terms even where `robots.txt` is permissive.
- **Prefer the official API over scraping** — it's usually less legally ambiguous, more stable, and not rate-limited into oblivion:
  - Naver Open API (search, blog, news, shopping, maps): https://developers.naver.com
  - Kakao Developers API (maps, local search, Daum properties): https://developers.kakao.com
  - DART (전자공시시스템, corporate filings): https://opendart.fss.or.kr — free API key, structured filings, far better than scraping the HTML viewer
  - data.go.kr (공공데이터포털): most government datasets are exposed as a REST API with a free key
- If scraping is genuinely the only option (no API covers the data), keep request rates low and identify a real `User-Agent` — don't spoof a browser to get around a block that exists specifically to stop bots. This skill is for legitimate collection (research, monitoring your own listings, price tracking with permission, OSINT with authorization), not for evading protections on sites that have decided not to allow it.

## 2. Encoding: don't assume UTF-8

Modern Korean sites (Naver, Daum, most SPAs) are UTF-8. But government sites, older corporate sites, and legacy e-commerce backends frequently still serve **EUC-KR** or its superset **CP949**, sometimes without a correct `Content-Type` charset header. Symptoms: garbled text like `占쏙옙` or `ï¿½` instead of Korean.

```python
import requests

resp = requests.get(url, headers=HEADERS)
resp.encoding = resp.apparent_encoding  # let chardet/charset-normalizer guess if headers lie

# If that still garbles Korean text, force it explicitly:
try:
    text = resp.content.decode("utf-8")
except UnicodeDecodeError:
    text = resp.content.decode("cp949", errors="replace")  # cp949 is the practical superset of euc-kr
```

Always try `utf-8` first, then fall back to `cp949` — don't hardcode `cp949` as the default or you'll mangle the (now more common) UTF-8 sites.

## 3. Static vs. JS-rendered pages

- **Static / server-rendered** (most government sites, DART, older corporate sites, plain blogs): `requests` + `BeautifulSoup` is enough.
- **JS-rendered** (Naver Blog/Cafe content iframes, Naver Shopping, Coupang product/review listings, most modern SPAs): the HTML from `requests` won't contain the data — use Playwright.
  - Naver Blog posts are served inside an iframe (`#mainFrame`) whose `src` is the actual content URL — fetch that URL directly instead of driving a full browser if you only need the post body; it's faster and lighter.
  - Naver Cafe requires login/membership for many boards — don't attempt to bypass membership gates.

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(locale="ko-KR")
    page.goto(url, wait_until="networkidle")
    html = page.content()
    browser.close()
```

Set `locale="ko-KR"` — some sites branch content or formatting (dates, currency) on locale.

## 4. Rate limits and bot defenses

Naver and Coupang in particular fingerprint aggressively and will serve a CAPTCHA (Naver's is reCAPTCHA-style) or block outright on bursty traffic. Don't try to automate CAPTCHA solving — that's a sign to slow down or switch to the official API, not to route around it. Practical mitigations:

- Throttle: 1 request every 1–3 seconds per host minimum for the big portals; back off further (exponential) on any 429/403.
- Set a realistic, current `User-Agent` and `Accept-Language: ko-KR,ko;q=0.9`.
- Reuse a `requests.Session()` (or persistent Playwright context) to keep cookies consistent rather than firing stateless requests.
- If you get blocked repeatedly, that's the site telling you scraping isn't welcome for this endpoint — check for an API alternative (§1) before trying to work around the block.

## 5. Korean-specific parsing notes

- **Phone numbers**: mobile is `010-XXXX-XXXX`; landlines vary by region code (`02` Seoul, `031` Gyeonggi, etc.). Strip separators (`-`, `.`, space) before validating format.
- **Business registration number** (사업자등록번호): format `XXX-XX-XXXXX`, useful for deduplicating/verifying companies scraped from listings.
- **Dates**: government and older sites often use `YYYY년 MM월 DD일` or `YYYY.MM.DD` rather than ISO — write a small normalizer rather than assuming one format across sites.
- **Text segmentation**: Korean doesn't space-delimit the way English does for search/matching purposes — if you need keyword extraction or morphological analysis (not just display), use `konlpy` (wraps Mecab/Okt) rather than naive whitespace splitting.

## 6. Reference request template

`scripts/fetch.py` in this skill has a working template (session reuse, encoding fallback, throttling, robots.txt check) — read it and adapt rather than writing the boilerplate from scratch each time.

## 7. Delivering structured research (OSINT / business-intelligence asks)

When the task is "find the people/contact info/org structure for these Korean companies" rather than a one-off page fetch, don't freelance the output shape — `references/output-format.md` documents a three-file deliverable (`<topic>.csv` + `<topic>.json` + `research_log.csv`) with a fixed schema, confidence levels, and an explicit log of anything declined and why. Read it before compiling the deliverable.

That reference also covers the recurring judgment call in these tasks: a brief asking for "human-like pacing to avoid IP/account-block triggers" against LinkedIn (or similar) is asking for anti-bot-detection evasion, not just data collection, even when the underlying data is public and professional — decline that specific part, say so in the output, and fall back to official sites, business registries, and public search-engine indexing for the same cross-references.
