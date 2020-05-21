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

This module installs [Borg Backup](https://www.borgbackup.org/) on nodes with
configuration to back up every day to a central server. The central server is
also configured, using exported resources to allow each node to have access to
its Borg repository.

## Setup

### What borg affects

The client side installs `borgbackup`, creates configuration in `/etc/borg`,
creates SSH configuration in `/root/.ssh` and sets up a cron job to run the
backup. A `borg::client` resource can be exported to automatically set up the
server side.

The server side simply creates a backup user (`borg` by default), installs
`borgbackup` and adds SSH authorized_keys entries for each exported client.

### Setup Requirements **OPTIONAL**

To use the exported resource feature you need to have
[PuppetDB](https://puppet.com/docs/puppetdb/latest/index.html) set up.

### Beginning with borg

To set up a client without exporting resources:
```
class {'borg':
    passphrase     => 'This is not a secure way to specify your passphrase',
    server_address => myborgserver.example.com,
}
```

To export a backup client resource, you should first generate an SSH key for root on
the node. You can do this with Puppet, or just:

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
    export_tag             => 'some-tag-for-this-server',
}
```

In my setup I expose the root public ssh key as a fact, so I can just use
`$facts['rootsshpubkey']` here. The `export_tag` is used by the server to
collect the exported resources. The default is `borg` which should work fine if
you're only setting up one server.

To set up the server itself, use the `borg::server` class:

```
include borg::server
```

The server has sensible defaults which you can override as needed:

```
class {'borg::server':
  base_dir   => '/largedisk/borg',
  export_tag => 'some-tag-for-this-server',
}
```

## Usage

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Reference

This section is deprecated. Instead, add reference information to your code as Puppet Strings comments, and then use Strings to generate a REFERENCE.md in your module. For details on how to add code comments and generate documentation with Strings, see the Puppet Strings [documentation](https://puppet.com/docs/puppet/latest/puppet_strings.html) and [style guide](https://puppet.com/docs/puppet/latest/puppet_strings_style.html)

If you aren't ready to use Strings yet, manually create a REFERENCE.md in the root of your module directory and list out each of your module's classes, defined types, facts, functions, Puppet tasks, task plans, and resource types and providers, along with the parameters for each.

For each element (class, defined type, function, and so on), list:

  * The data type, if applicable.
  * A description of what the element does.
  * Valid values, if the data type doesn't make it obvious.
  * Default value, if any.

For example:

```
### `pet::cat`

#### Parameters

##### `meow`

Enables vocalization in your cat. Valid options: 'string'.

Default: 'medium-loud'.
```

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other warnings.

## Development

In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header.
