# Universal-vagrant

## Overview

universal-vagrant makes it easy to get going with Vagrant.

universal-vagrant uses the precise32 box (Ubuntu 12.04 LTS) and sets up a LAMP stack (Apache 2.2 or 2.4, PHP 5.3 5.4 or 5.5, MySQL 5.5, Composer).
This project can be ideally used with any box.

This project was originally started by Anwar Ishak and forked from the original one at: [https://github.com/anwarishak/universal-vagrant](https://github.com/anwarishak/universal-vagrant).

This project is distributed **as-is** under the GPL-v2.

## Requirements

- At least 4GB of Memory
- Vagrant (tested with Vagrant 1.6.3
- VirtualBox (tested with VirtualBox 4.3.12)

## Installation

- Setup a common directory for all your projects, e.g. ~/Sites/
- `$ cd ~/Sites/`
- Clone the repo: `$ git clone https://github.com/ThePeach/universal-vagrant.git`. To avoid naming conflicts with other universal-vagrant folders, you can change the name of the directory into something more unique, e.g. `universal-vagrant-peach`. If you're doing so, remember to update the references to the repo accordingly in your `Vagrantfile` in each project.
- Clone your project into `~/Sites/` as well, e.g. `$ git clone http://url.to/mycoolproject.git`.
- `$ cp universal-vagrant/Vagrantfile-sample mycoolproject/Vagrantfile`.
- Amend the `Vagrantfile` based on the structure of your project and your needs:
    - `PATH_TO_UNIVERSAL_VAGRANT`: relative path to the universal-vagrant repo (e.g. `../universal-vagrant-peach/`)
    - `config.vm.hostname`: hostname for the box, might be useful when logging in
    - comment/uncomment `config.vm.provision` blocks based on your needs.
    - add relevant arguments to the provisioning scripts, see below for details.
- `$ cd mycoolproject`
- `$ vagrant up`

## Notes

- The new box will be accessible from [localhost:8080](http://localhost:8080), by default `vagrant up` will fail in case port 8080 is already taken, you might want to change the port or enable automatic adjustment of the port.

### Provisioning a specific version of PHP

By default the Vagrantfile will setup a LAMP box using **PHP 5.3**, if you need a different version, please adjust the arguments passed to the `LAMP-install.sh` script. It's always a good thing to add the `-v` flag to see some output.

The options available are:

- `-r <PROJECT_ROOT>`: absolute path of the projcet root in the vagrant VM (no trailing slash). Will default to `/vagrant` if not specified
- `-n <PHP_VERSION>`: (`php5.4` | `php5.5`). If not passed it will install the default version available from the official repo (currently php 5.3)

### MySQL database management

The `mysql.sh` script can take care of creating an additional empty database, a specific user for the database and fill it in with a specified snapshot. It's always a good thing to add the `-v` flag to see some output.

The available options are:

- `-d <DB_NAME>`: Name of the database to create. By default no db will be created.
- `-u <DB_USER>`: Name of the user to give credentials to the db <DB_NAME>. By default it will use user `root`.
- `-p <DB_PASS>`: Password for the <DB_USER>
- `-s <DB_SNAPSHOT>`: absolute path to the sql file to be used to fill the database, relative to the vagrant VM (e.g. `/vagrant/db/snapshot.sql`)

## TODO

- Enable XDebug in php.ini
- Add PHPMyAdmin to the provisioned software
