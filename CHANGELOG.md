## [Unreleased]

## [0.1.5](https://github.com/quintsys/firebase_hosting_client_ip/compare/v0.1.4...v0.1.5) (2025-12-12)


### Bug Fixes

* use official rubygems/release-gem action for publishing ([#18](https://github.com/quintsys/firebase_hosting_client_ip/issues/18)) ([4532dac](https://github.com/quintsys/firebase_hosting_client_ip/commit/4532dacfb193ae0aa553366468e9f1448cb5cc5f))
* use PAT instead of GITHUB_TOKEN for release-please ([#20](https://github.com/quintsys/firebase_hosting_client_ip/issues/20)) ([c87d8e6](https://github.com/quintsys/firebase_hosting_client_ip/commit/c87d8e623ea4ddb75b39ba20a8a9ffa4a9865be6))

## [0.1.4](https://github.com/quintsys/firebase_hosting_client_ip/compare/v0.1.3...v0.1.4) (2025-12-12)


### Bug Fixes

* trigger publish workflow after release-please creates release ([#16](https://github.com/quintsys/firebase_hosting_client_ip/issues/16)) ([551ff18](https://github.com/quintsys/firebase_hosting_client_ip/commit/551ff1867ad7d28600fe94876f551015d6294fe3))

## [0.1.3](https://github.com/quintsys/firebase_hosting_client_ip/compare/v0.1.2...v0.1.3) (2025-12-12)


### Bug Fixes

* use published event and OIDC auth for gem publishing ([#13](https://github.com/quintsys/firebase_hosting_client_ip/issues/13)) ([a1a9472](https://github.com/quintsys/firebase_hosting_client_ip/commit/a1a9472637302d6a655e864e9e530931c24bc1dd))

## [0.1.2](https://github.com/quintsys/firebase_hosting_client_ip/compare/v0.1.1...v0.1.2) (2025-12-12)


### Bug Fixes

* add explicit permissions to CI workflow ([#12](https://github.com/quintsys/firebase_hosting_client_ip/issues/12)) ([0cd88a1](https://github.com/quintsys/firebase_hosting_client_ip/commit/0cd88a135ed01aeb4e9bf122c6e864f75d647565))
* add workflow_dispatch to publish-gem workflow ([3da9e8f](https://github.com/quintsys/firebase_hosting_client_ip/commit/3da9e8f933d132bd50b758dc20570e8fdd6299f8))
* replace non-existent gem-push-action with standard gem commands ([#11](https://github.com/quintsys/firebase_hosting_client_ip/issues/11)) ([0bf888a](https://github.com/quintsys/firebase_hosting_client_ip/commit/0bf888a3f9a5e2d6ce15accc1b4f422bda0d711f))

## [0.1.1](https://github.com/quintsys/firebase_hosting_client_ip/compare/v0.1.0...v0.1.1) (2025-12-12)

### Bug Fixes

* update release-please action to non-deprecated version ([#8](https://github.com/quintsys/firebase_hosting_client_ip/issues/8)) ([1463650](https://github.com/quintsys/firebase_hosting_client_ip/commit/14636502355a7a387c561ca38c9fb64f00aa0265))

### Features

* implement Rails middleware to normalize client IP behind Firebase Hosting ([#5](https://github.com/quintsys/firebase_hosting_client_ip/pull/5))
* add release-please workflow for automated versioning and publishing ([#7](https://github.com/quintsys/firebase_hosting_client_ip/pull/7))

### Documentation

* add comprehensive README with usage examples and security disclaimers ([#6](https://github.com/quintsys/firebase_hosting_client_ip/pull/6))

### Testing

* add RSpec test coverage for middleware and Rails integration ([#6](https://github.com/quintsys/firebase_hosting_client_ip/pull/6))
* add GitHub Actions CI workflow for automated testing ([#6](https://github.com/quintsys/firebase_hosting_client_ip/pull/6))

## [0.1.0] - 2025-12-12

- Initial release
