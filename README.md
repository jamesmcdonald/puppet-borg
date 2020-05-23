# borg

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with borg](#setup)
    * [What borg affects](#what-borg-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with borg](#beginning-with-borg)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The `borg` module installs [Borg Backup](https://www.borgbackup.org/) on nodes
with configuration to back up every day to a central server. You can also
manage the central server itelf and use exported resources to allow each node
to have access to its Borg repository.

By default it will back up /etc, /home and /var/backups, but those paths are
configurable.

## Setup

### What borg affects

By default `borg` will modify `/root/.ssh/config` to add an `Include` directive
and add a `/root/.ssh/config-borg` with an alias `borg` pointing to the Borg
server. You can disable touching `/root/.ssh/config` with a parameter:

```
class {'borg':
  manage_root_ssh_config => false,
}
```

The `/root/.ssh` directory can also be managed, but that is disabled by default to avoid conflicts with other modules. You can enable it with:

```
class {'borg':
  manage_root_ssh_dir => true,
}
```

### Setup Requirements

To use the exported resource feature you need to have
[PuppetDB](https://puppet.com/docs/puppetdb/latest/index.html) set up.

### Beginning with borg

To set up a Borg client the only things you must specify are a passphrase and a
server address:

```
class {'borg':
    passphrase     => 'This is not a secure way to specify your passphrase',
    server_address => myborgserver.example.com,
}
```

To set up the server with its default settings, you need only include the class:

```
include ::borg::server
```

Automatic generation of exported resources is a little more complicated and is
discussed below.

## Usage

### Set up a client with exporting

To export a backup client resource, you should first generate an SSH key for
the user `root` on the node. You can do this with Puppet using
[ssh_keygen](https://forge.puppet.com/puppet/ssh_keygen), or create it manually:

```
ssh-keygen -t ed25519
```

You should make this key without a passphrase so it can be accessed by cron
jobs. Then you can set up the exporting as follows:

```
class {'borg':
    passphrase             => 'This is not a secure way to specify your passphrase',
    server_address         => myborgserver.example.com,
    export_backup_resource => true,
    ssh_public_key         => 'ED25519 key material from /root/.ssh/id_ed25519.pub',
}
```

In my setup I expose root's public ssh key as a fact, so I can just use
`$facts['rootsshpubkey']` here. You can also put the keys in Hiera, for example.

### Set up a server

You can set up a server with just:

```
include ::borg::server
```

The server will automatically collect all the exported backup resources and set
up SSH authorized_keys entries to allow each client access to its own repo.
Note that the server doesn't have any of the clients' encryption passphrases.

### Set up multiple combinations of clients and servers

The `export_tag` parameter is used by the server to collect the exported resources. The
default is `borg`, which should work fine if you're only setting up one server.

Both the `borg` and `borg::server` classes have this parameter.  Each instance
of `borg::server` will collect all exported clients tagged with the same value
`export_tag`. So you might have 2 borg servers with:

```
# borg1.example.com manifest
class {'borg::server':
  export_tag => 'clients1'
}
```

```
# borg2.example.com manifest
class {'borg::server':
  export_tag => 'clients2'
}
```

Then you can automatically enable a client to send backups to a particular server just by
setting `export_tag` to `clients1` or `clients2`.

### Customise client

The client has quite a few parameters. Here's an example of all of them just to
provide an overview of what's available.

```
class {'borg':
  # The passphrase used for Borg encryption
  passphrase => "something"
  # The address of the SSH server to send backups to
  server_address => "borg.example.com" 
  # The directories to back up
  directories => ['/var', '/usr']
  # Patterns to exclude
  excludes => ['/tmp']
  # Whether to manage /root/.ssh
  manage_root_ssh_dir => true,
  # Whether to manage /root/.ssh/config
  manage_root_ssh_config => true,
  # Whether to export the backup resource
  export_backup_resource => true,
  # The tag to mark the exported resource with
  export_tag => 'happybackup',
  # Root's ssh public key to use in the exported resource
  ssh_public_key => 'AAABCD='
  # A script to run before the backup
  prescript => "echo backup starting | mail root"
  # A script to run after the backup
  postscript => "touch /tmp/backupdone"
  # The name of the SSH alias to use in SSH config
  sshtarget => 'borg',
  # The username on the server side
  server_user => 'borg',
  # The URL of a Prometheus Pushgateway to send metrics to
  pushgateway_url => 'http://push',
  # A maximum age in seconds to pass to Prometheus for use in alerting
  maxage => 10000,
}
```

### Customise server

The server has sensible defaults but you can override as needed:

```
class {'borg::server':
  base_dir     => '/largedisk/borg',
  user         => 'gordo',
  export_tag   => 'some-tag-for-this-server',
  borg_package => 'otherborg',
}
```

## Limitations

Right now this module has only been tested on Debian, though it should also
work nicely on Debian derivatives. Support for macOS is likely to happen soon.

The way the parameters work could be a little nicer. Overriding
`borg::server_user` and `borg::export_tag` in Hiera will also affect the
default values used by `borg::server`, so it's possible to set them in one
place. I'm trying not to use a `params.pp` but it's not obvious how best to
manage common parameters without it.

## Development

Patches are welcome! Please get in touch on Gitlab if you have ideas or feedback.
