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
  Optional[String] $prescript,
  Optional[String] $postscript,
  String $sshtarget,
  String $server_user,
  Optional[String] $pushgateway_url,
  String $borgpackage,
  Boolean $remove_legacy = false,
){

  $package_options = $facts['kernel'] ? {
    'Darwin' => {
      ensure   => present,
      provider => 'brewcask',
    },
    default  => {
      ensure => present,
    },
  }
  ensure_packages($borgpackage, $package_options)

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

  file {'/usr/local/sbin/borg-backup':
    ensure  => file,
    mode    => '0700',
    content => epp('borg/backup.sh.epp', {
      maxage          => $maxage,
      sshtarget       => $sshtarget,
      pushgateway_url => $pushgateway_url,
      }),
  }

  file {'/usr/local/sbin/borg-restore':
    ensure => file,
    mode   => '0700',
    source => 'puppet:///modules/borg/restore.sh',
  }

  $roothome = $facts['kernel'] ? {
    'Darwin' => '/var/root',
    default  => '/root',
  }

  if $manage_root_ssh_dir {
    file {"${roothome}/.ssh":
      ensure => directory,
      mode   => '0700',
    }
  }

  if $manage_root_ssh_config {
    file {"${roothome}/.ssh/config":
      ensure => present,
      mode   => '0600',
    }

    file_line {'SSH wildcard config include':
      ensure => present,
      path   => "${roothome}/.ssh/config",
      line   => 'Include config-*',
    }
  }

  file {"${roothome}/.ssh/config-borg":
    ensure  => file,
    mode    => '0600',
    content => epp('borg/sshconfig.epp', {
      sshtarget => $sshtarget,
      server    => $server_address,
      user      => $server_user,
    }),
  }

  if $facts['kernel'] == 'Linux' {
    file {'/etc/cron.daily/borg-backup':
      ensure  => file,
      mode    => '0755',
      content => epp('borg/cronjob.epp', {
        prescript  => $prescript,
        postscript => $postscript,
      }),
    }
  }

  if $facts['kernel'] == 'Darwin' {
    $label = 'org.borgbackup.borg'
    $path = "/Library/LaunchDaemons/${label}.plist"
    file {$path:
      ensure  => file,
      content => epp('borg/launchd_plist.epp'),
      notify  => Exec["launchctl unload ${path}"],
    }

    exec {"launchctl unload ${path}":
      path        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      onlyif      => "launchctl list | grep -qw \"${label}\"",
      refreshonly => true,
      before      => Exec["launchctl load ${path}"],
    }

    exec {"launchctl load ${path}":
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      unless  => "launchctl list | grep -qw \"${label}\"",
      require => File[$path],
    }
  }

  if $export_backup_resource and $ssh_public_key != undef {
    @@borg::client {"borg-${facts['fqdn']}":
      fqdn => $facts['fqdn'],
      key  => $ssh_public_key,
      tag  => $export_tag,
    }
  }

  if $remove_legacy {
    include borg::remove_legacy
  }
}
