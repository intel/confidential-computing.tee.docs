#!/usr/bin/env python3
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: MIT

"""
Post-build link validator.

Scans all HTML files in the built site directory for cross-project links and verifies that the target exists in the site output.
MkDocs already validates relative links within each project.

See usage output of script for details and exit codes.
"""

from __future__ import annotations

import argparse
import os
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from html.parser import HTMLParser
from itertools import chain
from urllib.error import HTTPError, URLError
from urllib.parse import unquote, urlparse
from urllib.request import Request, urlopen


class LinkExtractor(HTMLParser):
    """Extract document links and static asset references from HTML."""

    def __init__(self) -> None:
        super().__init__()
        self.anchor_links: list[str] = []
        self.asset_links: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_dict = dict(attrs)
        if tag == "a":
            href = attr_dict.get("href")
            if href is not None:
                self.anchor_links.append(href)
        elif tag == "link":
            href = attr_dict.get("href")
            if href is not None:
                self.asset_links.append(href)
        elif tag in {"img", "script"}:
            src = attr_dict.get("src")
            if src is not None:
                self.asset_links.append(src)

# Per-domain locks: serialize requests to the same host so we don't trip rate-limiters / anti-bot measures.
_domain_locks: dict[str, threading.Lock] = {}
_domain_lock_guard = threading.Lock()


def _get_domain_lock(domain: str) -> threading.Lock:
    """Return a lock object dedicated to one domain.

    Args:
        domain: Hostname used as key for per-domain request serialization.

    Returns:
        A shared lock for the provided domain.
    """
    with _domain_lock_guard:
        if domain not in _domain_locks:
            _domain_locks[domain] = threading.Lock()
        return _domain_locks[domain]


def _fetch(url: str, user_agent: str, timeout: float) -> int | str:
    """Perform one HTTP check with HEAD-first strategy.

    The function first sends a HEAD request.
    If the server rejects HEAD or blocks it with 403, it retries with GET.

    Args:
        url: External URL to request.
        user_agent: User-Agent header to send with the request.
        timeout: Seconds to wait before the request times out.

    Returns:
        HTTP status code on response, or an error string on request failure.
    """
    req = Request(url, method="HEAD", headers={"User-Agent": user_agent})
    try:
        with urlopen(req, timeout=timeout) as resp:  # noqa: S310
            return resp.status
    except HTTPError as exc:
        if exc.code in (405, 403):
            try:
                req2 = Request(url, headers={"User-Agent": user_agent})
                with urlopen(req2, timeout=timeout) as resp:  # noqa: S310
                    return resp.status
            except HTTPError as exc2:
                return exc2.code
            except (URLError, OSError) as exc2:
                return str(exc2)
        return exc.code
    except (URLError, OSError) as exc:
        return str(exc)


def _check_url(
    url: str,
    user_agent: str,
    timeout: float,
    skip_domains: set[str],
    domain_delay: float,
    max_retries: int,
) -> tuple[str, int | str]:
    """Validate one external URL with throttling and retry behavior.

    Applies per-domain locking, delay between requests, and retry/backoff for HTTP 429 responses.

    Args:
        url: External URL to validate.
        user_agent: User-Agent header to send with requests.
        timeout: Seconds to wait before a request times out.
        skip_domains: Domains for which external validation is skipped.
        domain_delay: Seconds to wait between requests to the same domain.
        max_retries: Number of attempts for an external request that returns HTTP 429.

    Returns:
        Tuple ``(url, status)`` where ``status`` is an HTTP status code or an error string.
    """
    parsed = urlparse(url)
    domain = parsed.hostname or ""

    # skip known-blocked domains
    if any(domain == d or domain.endswith("." + d) for d in skip_domains):
        return url, 200

    lock = _get_domain_lock(domain)

    for attempt in range(max_retries):
        with lock:
            status = _fetch(url, user_agent, timeout)
            time.sleep(domain_delay)

        # Back off on 429 Too Many Requests (2 / 4 / 8 s)
        if isinstance(status, int) and status == 429:
            time.sleep(2 ** (attempt + 1))
            continue

        return url, status

    # exhausted retries
    return url, 429


def extract_links(
    site_dir: str,
) -> tuple[list[tuple[str, str]], set[str]]:
    """Scan generated HTML files and collect cross-project and external links.

    The document-link pass collects ``<a href>`` values.
    The static asset pass collects ``<link href>``, ``<img src>``, and ``<script src>`` values.

    Ignores non-HTML files and ``404.html`` pages.

    Args:
        site_dir: Root path of the built MkDocs site.

    Returns:
        cross_project_links: list of (html_file_relative, href) for cross-project links
        external_links: set of unique external links (anchors stripped)
    """
    cross_project_links: list[tuple[str, str]] = []
    external_links: set[str] = set()

    for root, _, files in os.walk(site_dir):
        for fname in files:
            if not fname.endswith(".html"):
                continue

            # Skip 404 pages: their nav links use project-scoped paths that don't resolve from the site root.
            if fname == "404.html":
                continue

            html_path = os.path.join(root, fname)
            with open(html_path, encoding="utf-8", errors="replace") as fh:
                content = fh.read()

            extractor = LinkExtractor()
            extractor.feed(content)

            # Compute relative path of HTML file from site root for reporting.
            rel_html = os.path.relpath(html_path, site_dir)

            # Process document and static-asset links found in the HTML file.
            # Make sure to ignore any anchors (fragment identifiers) when checking external links.
            for href in chain(extractor.anchor_links, extractor.asset_links):
                parsed = urlparse(href)

                # Ignore links that are not cross-project or external (e.g., relative links within the same project).
                if parsed.scheme in ("http", "https"):
                    clean = href.split("#")[0]
                    if clean:
                        external_links.add(clean)
                elif not parsed.scheme and not parsed.netloc:
                    path = unquote(parsed.path)
                    if path.startswith("/"):
                        cross_project_links.append((rel_html, href))

    return cross_project_links, external_links


def validate_cross_project_links(
    site_dir: str, links: list[tuple[str, str]], verbose: bool = False
) -> list[tuple[str, str]]:
    """Validate cross-project links against files in the built site output.

    Args:
        site_dir: Root path of the built MkDocs site.
        links: List of ``(html_file_relative, href)`` tuples to validate.
        verbose: If ``True``, print each link while it is being checked.

    Returns:
        List of ``(html_file_relative, broken_href)`` entries for links that do not resolve under ``site_dir``.
    """
    broken: list[tuple[str, str]] = []
    for html_file, href in links:
        if verbose:
            print(f"  [cross-project] checking: {href}  ({html_file})")

        path = unquote(urlparse(href).path)
        rel = path.lstrip("/")
        target = os.path.join(site_dir, rel)
        if target.endswith("/") or os.path.isdir(target):
            target = os.path.join(target, "index.html")
        is_ok = os.path.isfile(target)

        if not is_ok:
            broken.append((html_file, href))
    return broken


def validate_external_links(
    links: set[str],
    user_agent: str,
    timeout: float,
    skip_domains: set[str],
    domain_delay: float,
    max_retries: int,
    max_workers: int = 10,
    verbose: bool = False,
) -> list[tuple[str, int | str]]:
    """Validate external links concurrently and return only failing results.

    Args:
        links: Set of unique external HTTP/HTTPS URLs to validate.
        user_agent: User-Agent header to send with requests.
        timeout: Seconds to wait before a request times out.
        skip_domains: Domains for which external validation is skipped.
        domain_delay: Seconds to wait between requests to the same domain.
        max_retries: Number of attempts for an external request that returns HTTP 429.
        max_workers: Maximum number of concurrent worker threads used for checks.
        verbose: If ``True``, print each link while it is being checked.

    Returns:
        List of ``(url, status)`` tuples for links that did not return an HTTP 2xx status.
        ``status`` is either an integer HTTP status code or an error string when a request fails before receiving an HTTP response.
    """
    broken: list[tuple[str, int | str]] = []
    total = len(links)
    done = 0
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futures = {}
        for url in sorted(links):
            if verbose:
                print(f"  [external] checking: {url}")
            futures[
                pool.submit(
                    _check_url,
                    url,
                    user_agent,
                    timeout,
                    skip_domains,
                    domain_delay,
                    max_retries,
                )
            ] = url

        for future in as_completed(futures):
            done += 1
            url, status = future.result()
            if isinstance(status, int) and 200 <= status < 300:
                continue
            broken.append((url, status))
            if done % 40 == 0:
                print(f"  ... checked {done}/{total} external URLs", flush=True)

    if done >= 40:
        print(f"  ... checked {done}/{total} external URLs", flush=True)

    return broken


def main() -> None:
    """Run the CLI entry point for link extraction and validation."""
    parser = argparse.ArgumentParser(
        prog="validate_links.py",
        description=(
            "Validate cross-project links in a built MkDocs site and, "
            "optionally, external HTTP/HTTPS links."
        ),
        epilog=(
            "Exit codes: 0=all checked links resolve, "
            "1=one or more broken links found, "
            "2=invalid arguments or missing site directory"
        ),
    )
    parser.add_argument(
        "site_dir",
        nargs="?",
        default="site",
        help="Built MkDocs site directory (default: site)",
    )
    parser.add_argument(
        "--check-external",
        action="store_true",
        help="Also validate external HTTP/HTTPS URLs",
    )
    parser.add_argument(
        "--user-agent",
        default=(
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ),
        help="User-Agent header for external requests",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=15,
        help="Seconds to wait for each external request (default: 15)",
    )
    parser.add_argument(
        "--skip-domain",
        action="append",
        metavar="DOMAIN",
        default=["linkedin.com", "www.linkedin.com", "linux.die.net"],
        help=(
            "Skip validation for DOMAIN and its subdomains; may be repeated "
            "(default: linkedin.com, www.linkedin.com, linux.die.net)"
        ),
    )
    parser.add_argument(
        "--domain-delay",
        type=float,
        default=0.5,
        help="Seconds to wait between requests to the same domain (default: 0.5)",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=3,
        help="Attempts for external requests that return HTTP 429 (default: 3)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print each link while it is being checked",
    )

    parsed_args = parser.parse_args()

    site_dir = parsed_args.site_dir
    check_external = parsed_args.check_external
    verbose = parsed_args.verbose
    user_agent = parsed_args.user_agent
    timeout = parsed_args.timeout
    skip_domains = set(parsed_args.skip_domain)
    domain_delay = parsed_args.domain_delay
    max_retries = parsed_args.max_retries

    if not os.path.isdir(site_dir):
        print(f"Error: site directory '{site_dir}' not found.", file=sys.stderr)
        print("Build documentation first.", file=sys.stderr)
        parser.print_usage(sys.stderr)
        sys.exit(2)

    # Extract all links.
    cross_project_links, external_urls = extract_links(site_dir)
    has_errors = False

    # Validate cross-project links and print all broken links.
    print(f"\nChecking {len(cross_project_links)} cross-project links ...")
    broken_cross_project_links = validate_cross_project_links(site_dir, cross_project_links, verbose=verbose)
    if broken_cross_project_links:
        unique = sorted(set(broken_cross_project_links))
        print(f"\n{'='*70}")
        print(f" BROKEN CROSS-PROJECT LINKS: {len(unique)} found")
        print(f"{'='*70}\n")
        for html_file, href in unique:
            print(f"  {html_file}")
            print(f"    → {href}\n")
        has_errors = True
    else:
        print("All cross-project links validated successfully.")

    # Validate external links and print all broken links (opt-in).
    if check_external:
        print(f"\nChecking {len(external_urls)} external links ...")
        broken_external_links = validate_external_links(
            external_urls,
            user_agent,
            timeout,
            skip_domains,
            domain_delay,
            max_retries,
            verbose=verbose,
        )
        if broken_external_links:
            broken_external_links.sort(key=lambda t: t[0])
            print(f"\n{'='*70}")
            print(f" BROKEN EXTERNAL LINKS: {len(broken_external_links)} found")
            print(f"{'='*70}\n")
            for url, status in broken_external_links:
                print(f"  {status}  {url}")
            print()
            has_errors = True
        else:
            print("All external links validated successfully.")

    sys.exit(1 if has_errors else 0)


if __name__ == "__main__":
    main()
