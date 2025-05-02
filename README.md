[![Codacy Badge](https://app.codacy.com/project/badge/Grade/63aa21dd1caf4dac898ba695ce6a57e7)](https://app.codacy.com/gh/JasonN3/fedora_base/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# Base Fedora Image

This repo is meant as an example of what is possible with Image Mode. This repo contains no secrets and instead uses a SystemD service to configure the system on startup. The packages required for the configuration are built into the container image. This allows for publicly stored images while still allowing secure information to be stored on the resulting machine.

Under normal circumstances, the preferred approach is to store all of your configurations in their final state within the container image, but that will not always be an option

The resulting image is the baseline image for my OS images. From there, [Fedora Workstation](https://github.com/JasonN3/fedora_workstation) and [Fedora Server](https://github.com/JasonN3/fedora_server) are created. If you would like to create something similar for yourself, please feel free to fork the repo.
