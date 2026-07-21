# Copyright (C) 2025 - 2026 Intel Corporation
# SPDX-License-Identifier: MIT

FROM squidfunk/mkdocs-material:9.7.7

WORKDIR /repo/docs/parent_doc

COPY requirements.txt /repo/docs/parent_doc/requirements.txt

# Install additional MkDocs plugins
RUN pip install -r requirements.txt

# Trust mounted repository path for git metadata plugins
RUN git config --system --add safe.directory /repo

ENTRYPOINT ["/sbin/tini", "--", "mkdocs", "serve", "--dev-addr=0.0.0.0:8000", "--livereload"]
