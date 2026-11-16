ARG DOCKER_IMAGE_TAG_PLAYWRIGHT=latest \
    VERSION_UV=latest
FROM ghcr.io/astral-sh/uv:${VERSION_UV} AS uv
FROM mcr.microsoft.com/playwright/python:${DOCKER_IMAGE_TAG_PLAYWRIGHT}
ARG VERSION_MANAGED_SETTINGS_JSON
ARG VERSION_CLAUDE_CODE
WORKDIR /workspace
# - Using uv in Docker | uv
#   https://docs.astral.sh/uv/guides/integration/docker/#caching
ENV UV_LINK_MODE=copy
# - Using uv in Docker | uv
#   https://docs.astral.sh/uv/guides/integration/docker/#installing-uv
COPY --from=uv /uv /uvx /bin/
# Reason: Debian stable (fixed by the base image) only receives security and critical fixes,
#         and pinning a suite such as `/stable` would exclude the fixes from `trixie-security`.
# hadolint ignore=DL3008
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
    # To enable Claude Code sandbox
    bubblewrap \
    socat \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
# Force the Claude Code sandbox on for every session in this container:
# managed settings take precedence over user/project settings and cannot be
# overridden from inside a session.
# - Enterprise sandbox settings and managed policy settings - Claude Code Docs
#   https://code.claude.com/docs/en/sandboxing#enterprise-sandbox-settings
#   https://code.claude.com/docs/en/settings#managed-settings
# Source: https://github.com/yukihiko-shinoda/claude-code-settings-file/blob/main/managed-settings.json
# Pinned to a commit SHA so the policy cannot change under us; bump manually.
# ADD creates /etc/claude-code automatically; remote files default to mode 0600, so set 0644 explicitly.
ADD --chmod=0644 https://raw.githubusercontent.com/yukihiko-shinoda/claude-code-settings-file/${VERSION_MANAGED_SETTINGS_JSON}/managed-settings.json /etc/claude-code/managed-settings.json
# Claude Code
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${VERSION_CLAUDE_CODE}"
ENV DISABLE_AUTOUPDATER=1
ENTRYPOINT ["uv", "run"]
CMD ["pytest"]
