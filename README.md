Ubuntu
======

[`ubuntu`](https://ghcr.io/sgsgermany/ubuntu) is [@SGSGermany](https://github.com/SGSGermany)'s base image for containers based on [Ubuntu](https://ubuntu.com/). This image is built *daily* at 21:20 UTC on top of the [official Docker image](https://hub.docker.com/_/ubuntu) using [GitHub Actions](https://github.com/SGSGermany/ubuntu/actions/workflows/container-publish.yml).

Rebuilds are triggered only if Ubuntu builds a new image, or if one of the [`ubuntu-oci` base packages](https://git.launchpad.net/cloud-images/+oci/ubuntu-base/) were updated. Currently we create images for both **Ubuntu 24.04 "Noble Numbat"** and **Ubuntu 22.04 "Jammy Jellyfish"**. Please note that we might add or drop branches at any time, but usually around upstream's release resp. end-of-life dates.

All images are tagged with their Ubuntu version string, build date and build job number (e.g. `v22.04-20190618.1658821493.1`), as well as with the release branch's short codename (e.g. `jammy-20190618.1658821493.1`). The latest build of an Ubuntu release is additionally tagged without the build information (e.g. `v22.04` and `jammy`). The latest build of the latest Ubuntu LTS release is furthermore tagged with `latest`.

Licensing
---------

Made with ♥ by [SGS Serious Gaming & Simulations](https://www.sgs-online.info).

This repository contains scripts and resources for building and continuously integrating an OCI container image, as well as components used to run it (e.g., setup scripts, runtime configuration, modified config files).

All contents of this repository are free and open-source software, licensed under the terms of the [MIT License](./LICENSE).

Please note that the resulting OCI container image includes not only the components provided in this repository, but also the third-party components constituting the operating system included in the image. These are licensed under their respective licenses and are not covered by the MIT License of this repository. Please refer to the respective component licenses for details.
