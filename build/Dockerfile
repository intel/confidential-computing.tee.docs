# Copyright (C) 2025 - 2026 Intel Corporation
# SPDX-License-Identifier: MIT

FROM squidfunk/mkdocs-material:9.7.7

WORKDIR /docs

COPY requirements.txt /docs/requirements.txt

# Install additional MkDocs plugins
RUN pip install -r requirements.txt

ENTRYPOINT ["/sbin/tini", "--", "mkdocs", "serve", "--dev-addr=0.0.0.0:8000", "--livereload"]
