# Set up stuff on the borg server
class borg::server (
  String $base_dir,
  String $user = lookup('borg::server_user'),
  String $export_tag = lookup('borg::export_tag'),
  String $borgpackage = lookup('borg::borgpackage'),
){
  ensure_packages($borgpackage)

  file {$base_dir:
    ensure => directory,
    mode   => '0700',
    owner  => $user,
    group  => $user,
  }

  user {$user:
    ensure => present,
    home   => $base_dir,
  }

  Borg::Client <<| tag==$export_tag |>> {
    borg_base => $base_dir,
    borg_user => $user,
  }
}
