# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: MIT

"""Shared macros module for parent and child MkDocs builds.

Current responsibilities
------------------------
This module currently focuses on one concrete task:

1. Runtime URL adjustment for local/CI builds
    - Rewrites ``config.repo_url`` to the active repository remote.
    - Rewrites the branch segment in ``config.edit_uri`` to the active branch.
    - Behavior is enabled only when ``LOCAL_DEPLOYMENT`` is set.

Why this exists
---------------
The same documentation sources are built in several environments:

- Developer laptops (feature branches, forks)
- CI (GitHub Actions and branch-specific builds)
- Production publishing

Without dynamic adjustment, "Edit this page" / "View source" links can point to
the wrong repository or branch during local and CI validation.

Extension points
----------------
This module is intentionally structured so additional macros behavior can be
added without touching MkDocs templates:

- Add more Jinja filters in ``define_env``.
- Add more environment-aware config normalization helpers.
- Add diagnostics for config drift across parent/child projects.
"""

from __future__ import annotations

import logging
import os
import subprocess

log = logging.getLogger("mkdocs.macros.repo_url")


def _git(*args: str) -> str | None:
    """Run a git command and return stripped stdout, or ``None`` on failure."""
    try:
        return subprocess.check_output(
            ["git", *args],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def _remote_to_https(remote: str) -> str:
    """Convert SSH/HTTPS remote URL to normalized HTTPS URL."""
    if remote.startswith("git@"):
        remote = remote.replace(":", "/", 1).replace("git@", "https://", 1)
    return remote.removesuffix(".git").rstrip("/") + "/"


def _detect_repo_url(remote_name: str) -> str | None:
    """Detect repository URL from CI environment or local git remote."""
    gh_server = os.environ.get("GITHUB_SERVER_URL", "").rstrip("/")
    gh_repo = os.environ.get("GITHUB_REPOSITORY", "")
    if gh_server and gh_repo:
        return f"{gh_server}/{gh_repo}/"

    remote = _git("remote", "get-url", remote_name)
    if remote:
        return _remote_to_https(remote)

    return None


def _detect_branch(remote_name: str) -> str | None:
    """Detect branch to embed into ``edit_uri``."""
    # CI-provided branch/ref takes precedence.
    ref = os.environ.get("GITHUB_REF_NAME", "")
    if ref:
        return ref

    # Local branch for developer builds.
    branch = _git("branch", "--show-current")
    if branch:
        return branch

    # Detached HEAD fallback: use the remote's default branch.
    head = _git("symbolic-ref", f"refs/remotes/{remote_name}/HEAD")
    if head:
        return head.rsplit("/", 1)[-1]

    return None


def _replace_branch(edit_uri: str, new_branch: str) -> str:
    """Replace branch segment in ``edit_uri`` (``<action>/<branch>/<path>``)."""
    parts = edit_uri.split("/", 2)
    if len(parts) >= 2:
        parts[1] = new_branch
    return "/".join(parts)


def _apply_local_url_adjustments(env) -> None:
    """Apply all URL-related config adjustments for local/CI execution.

    Current adjustments:
    - ``repo_url``: set to detected remote/CI repository URL when available.
    - ``edit_uri``: swap the branch segment to the detected branch/ref.
    """

    # Guard: only rewrite URLs for local/CI builds, never for production.
    if not os.environ.get("LOCAL_DEPLOYMENT"):
        return

    # Use the active config for this project (parent or child build).
    config = env.conf

    # Allow overriding the git remote name when multiple remotes exist.
    remote_name = os.environ.get("MKDOCS_REPO_REMOTE", "origin")

    # Update repo_url to the detected repository for Edit/View source links.
    repo_url = _detect_repo_url(remote_name)
    if repo_url is not None:
        config["repo_url"] = repo_url

    # Update edit_uri to point at the active branch or CI ref.
    branch = _detect_branch(remote_name)
    if branch is not None:
        old_uri = config.get("edit_uri", "")
        new_uri = _replace_branch(old_uri, branch)
        if old_uri != new_uri:
            log.info("repo_url macro: edit_uri %r → %r", old_uri, new_uri)
            config["edit_uri"] = new_uri


def define_env(env):
    """Entry point called by mkdocs-macros-plugin during configuration.

    Notes:
    - Runs once per MkDocs project build (parent and each child).
    - Can register Jinja filters and mutate ``env.conf``.
    - Uses environment flags to keep production behavior unchanged by default.
    """

    _apply_local_url_adjustments(env)
