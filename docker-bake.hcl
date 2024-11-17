variable "VERSION" {
  default = "latest"
}

target "docker-metadata-action" {}

target "_common" {
  inherits = ["docker-metadata-action"]
  context = "."
  dockerfile = "Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v6",
    "linux/arm/v7"
  ]
  tags = [
    "ttionya/vaultwarden-backup:latest",
    "ttionya/vaultwarden-backup:${VERSION}",
    "ttionya/bitwardenrs-backup:latest",
    "ttionya/bitwardenrs-backup:${VERSION}",
    "ghcr.io/ttionya/vaultwarden-backup:latest",
    "ghcr.io/ttionya/vaultwarden-backup:${VERSION}"
  ]
}

target "image-stable" {
  inherits = ["_common"]
}

target "image-schedule" {
  inherits = ["image-stable"]
}

target "image-beta" {
  inherits = ["_common"]
  tags = [
    "ttionya/vaultwarden-backup:${VERSION}"
  ]
}

target "image-test-base" {
  inherits = ["_common"]
  tags = [
    "localhost:5000/base:dev"
  ]
}

target "image-test" {
  inherits = ["_common"]
  dockerfile = "./tests/Dockerfile"
  contexts = {
    base = "docker-image://localhost:5000/base:dev"
  }
  tags = [
    "ttionya/vaultwarden-backup:test"
  ]
}
