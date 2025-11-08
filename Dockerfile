ARG DOCKER_IMAGE_TAG_PLAYWRIGHT=latest \
    VERSION_UV=latest
FROM ghcr.io/astral-sh/uv:${VERSION_UV} AS uv
FROM mcr.microsoft.com/playwright:${DOCKER_IMAGE_TAG_PLAYWRIGHT}
ARG VERSION_CLAUDE_CODE=latest
WORKDIR /workspace
# - Using uv in Docker | uv
#   https://docs.astral.sh/uv/guides/integration/docker/#installing-uv
COPY --from=uv /uv /uvx /bin/
# - Using uv in Docker | uv
#   https://docs.astral.sh/uv/guides/integration/docker/#caching
ENV UV_LINK_MODE=copy
RUN npm install -g @anthropic-ai/claude-code@${VERSION_CLAUDE_CODE}
ENV DISABLE_AUTOUPDATER=1
# The uv command also errors out when installing semgrep:
# - Getting semgrep-core in pipenv · Issue #2929 · semgrep/semgrep
#   https://github.com/semgrep/semgrep/issues/2929#issuecomment-818994969
ENV SEMGREP_SKIP_BIN=true
ENTRYPOINT ["uv", "run"]
CMD ["pytest"]
