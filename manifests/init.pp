# Set up borg
class borg (
  String $passphrase,
  Integer $maxage = 129600,
  Array[String] $directories = ['/etc', '/home', '/var/backups'],
  Array[String] $excludes = [],
  Boolean $manage_root_ssh_dir = false,
  Boolean $manage_root_ssh_config = true,
  Boolean $export_backup_resource = false,
  String $export_tag = 'borg',
  Optional[String] $ssh_public_key = undef,
){
  package {'borgbackup':
    ensure => present,
  }

  file {'/etc/borg':
    ensure => directory,
    mode   => '0700',
  }

  file {'/etc/borg/directories':
    ensure  => file,
    mode    => '0600',
    content => epp('profile/borg/filelist.epp', {
      files => $directories,
      }),
  }

  file {'/etc/borg/excludes':
    ensure  => file,
    mode    => '0600',
    content => epp('profile/borg/filelist.epp', {
      files => $excludes,
      }),
  }

  file {'/etc/borg/passphrase':
    ensure  => file,
    mode    => '0600',
    content => $passphrase,
  }

  file {'/usr/local/sbin/backup':
    ensure => file,
    mode   => '0700',
    content => epp('profile/borg/backup.sh.epp', {
      maxage => $maxage,
      }),
  }

  file {'/usr/local/sbin/restore':
    ensure  => file,
    mode    => '0700',
    source  => 'puppet:///modules/profile/borg/restore.sh',
  }

  if $manage_root_ssh_dir {
    file {'/root/.ssh':
      ensure => directory,
      mode   => '0700',
    }
  }

  if $manage_root_ssh_config {
    file {'/root/.ssh/config':
      ensure => present,
      mode   => '0600',
    }

    file_line {'SSH wildcard config include':
      ensure => present,
      path   => '/root/.ssh/config',
      line   => 'Include config-*',
    }
  }

  file {'/root/.ssh/config-borg':
    ensure => file,
    mode   => '0600',
    source => 'puppet:///modules/profile/borg/sshconfig',
  }

  file {'/etc/cron.daily/backup':
    ensure  => file,
    mode    => '0755',
    content => "#!/bin/bash\n/usr/local/sbin/backup\n",
  }

  if $export_backup_resource and defined($ssh_public_key) {
    @@borg::client {"borg-${facts['fqdn']}":
      fqdn => $facts['fqdn'],
      key  => $ssh_public_key,
      tag  => $export_tag,
    }
  }
}
