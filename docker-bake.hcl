variable "DOCKER_TAG" {
}
target "claude-code-playwright-python" {
  tags = [
    "futureys/claude-code-playwright-python:latest",
    "futureys/claude-code-playwright-python:${DOCKER_TAG}",
  ]
}
// To prevent following error when testing `docker buildx bake` in development PC:
//   ERROR: Multi-platform build is not supported for the docker driver.
//   Switch to a different driver, or turn on the containerd image store, and try again.
//   Learn more at https://docs.docker.com/go/build-multi-platform/
target "app-release" {
  inherits = ["claude-code-playwright-python"]
  platforms = ["linux/amd64", "linux/arm64"]
}
