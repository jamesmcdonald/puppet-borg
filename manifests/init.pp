# Install and configure Borg.
class borg (
  String $passphrase,
  String $server_address,
  Integer $maxage,
  Array[String] $directories,
  Array[String] $excludes,
  Boolean $manage_root_ssh_dir,
  Boolean $manage_root_ssh_config,
  Boolean $export_backup_resource,
  String $export_tag,
  Optional[String] $ssh_public_key,
  String $prescript,
  String $postscript,
  String $sshtarget,
  String $server_user,
  String $pushgateway_url,
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
    content => epp('borg/filelist.epp', {
      files => $directories,
      }),
  }

  file {'/etc/borg/excludes':
    ensure  => file,
    mode    => '0600',
    content => epp('borg/filelist.epp', {
      files => $excludes,
      }),
  }

  file {'/etc/borg/passphrase':
    ensure  => file,
    mode    => '0600',
    content => $passphrase,
  }

  file {'/usr/local/sbin/backup':
    ensure  => file,
    mode    => '0700',
    content => epp('borg/backup.sh.epp', {
      maxage          => $maxage,
      sshtarget       => $sshtarget,
      pushgateway_url => $pushgateway_url,
      }),
  }

  file {'/usr/local/sbin/restore':
    ensure => file,
    mode   => '0700',
    source => 'puppet:///modules/borg/restore.sh',
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
    ensure  => file,
    mode    => '0600',
    content => epp('borg/sshconfig.epp', {
      sshtarget => $sshtarget,
      server    => $server_address,
      user      => $server_user,
    }),
  }

  file {'/etc/cron.daily/backup':
    ensure  => file,
    mode    => '0755',
    content => epp('borg/cronjob.epp', {
      prescript  => $prescript,
      postscript => $postscript,
    }),
  }

  if $export_backup_resource and $ssh_public_key != undef {
    @@borg::client {"borg-${facts['fqdn']}":
      fqdn => $facts['fqdn'],
      key  => $ssh_public_key,
      tag  => $export_tag,
    }
  }
}
