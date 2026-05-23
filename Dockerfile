ARG DOCKER_IMAGE_TAG_PLAYWRIGHT=latest \
    VERSION_UV=latest
FROM ghcr.io/astral-sh/uv:${VERSION_UV} AS uv
FROM mcr.microsoft.com/playwright/python:${DOCKER_IMAGE_TAG_PLAYWRIGHT}
ARG VERSION_CLAUDE_CODE=latest
WORKDIR /workspace
# - Using uv in Docker | uv
#   https://docs.astral.sh/uv/guides/integration/docker/#caching
ENV UV_LINK_MODE=copy
# - Using uv in Docker | uv
#   https://docs.astral.sh/uv/guides/integration/docker/#installing-uv
COPY --from=uv /uv /uvx /bin/
RUN apt-get update && apt-get install --no-install-recommends -y \
    #   For `ps` command, otherwise following error occurs when running claude-code::
    # - [BUG] Node.js error when `ps` is unavailable · Issue #2276 · anthropics/claude-code
    #   https://github.com/anthropics/claude-code/issues/2276
    procps \
    #   For running Semgrep, otherwise following error occurs:
    #   Fatal error: exception Failure: ca-certs: no trust anchor file found, looked into
    #     /etc/ssl/certs/ca-certificates.crt,
    #     /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem,
    #     /etc/ssl/ca-bundle.pem.
    ca-certificates \
    # To install Claude Code
    curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
# Claude Code
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${VERSION_CLAUDE_CODE}"
ENV DISABLE_AUTOUPDATER=1
ENTRYPOINT ["uv", "run"]
CMD ["pytest"]
