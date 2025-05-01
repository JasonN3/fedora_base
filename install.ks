clearpart --all
autopart --nohome
keyboard --xlayouts=us

ostreecontainer --url=ghcr.io/jasonn3/fedora_base:pr-2 --transport=registry --no-signature-verification