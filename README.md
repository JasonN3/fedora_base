[![Codacy Badge](https://app.codacy.com/project/badge/Grade/63aa21dd1caf4dac898ba695ce6a57e7)](https://app.codacy.com/gh/JasonN3/fedora_base/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# Base Fedora Image

This repo is meant as an example of what is possible with Image Mode. This repo contains no secrets and instead uses a separate repo for any configuration information. The last layer that contains the generated configurations is then encrypted so it can only be read by the desired machines.

To ensure that none of the base OS is modified in an unexpected way, the service `protect_etc` was created to reset any files that do not match the base image. Files can be excluded by listing them in `/etc/protect_etc/files.exclude`

Any applications that need to run on the system are then launched using podman either as a systemd service or through flightctl.

If you would like to create something similar for yourself, please feel free to fork the repo.
