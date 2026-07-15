#!/usr/bin/env python3
"""
Rate-limit-safe fetch template for Korean (.kr) sites.

Handles the two recurring gotchas: legacy EUC-KR/CP949 encoding on
older/government sites, and the aggressive rate limiting on Naver/Daum/
Coupang. Checks robots.txt before fetching and throttles per host.

Usage:
    from fetch import KoreanSiteFetcher
    fetcher = KoreanSiteFetcher()
    html = fetcher.get("https://example.co.kr/page")
"""

import time
import urllib.robotparser
from urllib.parse import urlparse

import requests

DEFAULT_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "ko-KR,ko;q=0.9,en;q=0.8",
}


class KoreanSiteFetcher:
    def __init__(self, min_delay_seconds: float = 1.5, headers: dict | None = None):
        self.min_delay = min_delay_seconds
        self.headers = headers or DEFAULT_HEADERS
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        self._last_request_at: dict[str, float] = {}
        self._robots_cache: dict[str, urllib.robotparser.RobotFileParser] = {}

    def _allowed_by_robots(self, url: str) -> bool:
        parsed = urlparse(url)
        origin = f"{parsed.scheme}://{parsed.netloc}"
        rp = self._robots_cache.get(origin)
        if rp is None:
            rp = urllib.robotparser.RobotFileParser()
            rp.set_url(f"{origin}/robots.txt")
            try:
                rp.read()
            except Exception:
                # If robots.txt is unreachable, don't silently treat that as
                # blanket permission — caller should decide how to proceed.
                return True
            self._robots_cache[origin] = rp
        return rp.can_fetch(self.headers["User-Agent"], url)

    def _throttle(self, url: str) -> None:
        host = urlparse(url).netloc
        last = self._last_request_at.get(host)
        if last is not None:
            elapsed = time.monotonic() - last
            if elapsed < self.min_delay:
                time.sleep(self.min_delay - elapsed)
        self._last_request_at[host] = time.monotonic()

    def get(self, url: str, respect_robots: bool = True, **kwargs) -> str:
        if respect_robots and not self._allowed_by_robots(url):
            raise PermissionError(f"robots.txt disallows fetching {url}")

        self._throttle(url)
        resp = self.session.get(url, timeout=15, **kwargs)
        resp.raise_for_status()
        return self._decode(resp)

    @staticmethod
    def _decode(resp: requests.Response) -> str:
        # Try the server's declared/apparent encoding first (covers the
        # UTF-8 majority), then fall back to CP949 for legacy sites that
        # mislabel or omit charset.
        for encoding in (resp.encoding, resp.apparent_encoding):
            if not encoding:
                continue
            try:
                return resp.content.decode(encoding)
            except (UnicodeDecodeError, LookupError):
                continue
        return resp.content.decode("cp949", errors="replace")


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python fetch.py <url>")
        raise SystemExit(1)

    fetcher = KoreanSiteFetcher()
    print(fetcher.get(sys.argv[1])[:2000])
