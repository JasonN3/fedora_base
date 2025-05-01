keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8


clearpart --all --initlabel
autopart --nohome

timezone America/New_York

ostreecontainer --url=ghcr.io/jasonn3/fedora_base:pr-2 --transport=registry --no-signature-verification