# infra

This repository contains everything related to `joris.me` infrastructure:

- Documentation:
    - `/diagrams` contain machine, network and deployment diagrams
    - `/docs` contains the documents available at [docs.joris.me](https://docs.joris.me)
- Bootstrapping:
    - `/scripts` contain init scripts, `cloud-init.yml`
    - `/static`
- Management:
    - `/roles` contains Ansible roles;
    - `/playbooks` contains Ansible playbooks;
    - `/inventory` contains Ansible inventories.

## Ansible

Make sure to [install the Ansible dependencies](#install-ansible-dependencies) first.

### Install Ansible dependencies

Run this **locally**, on your machine:

```bash
$ ansible-galaxy collection install community.docker
```

### Updating hosts
Runs `apt update && apt upgrade` and ensures some general packages are installed.

```bash
$ ansible-playbook -i inventory/test.yml playbooks/update.yml
```
