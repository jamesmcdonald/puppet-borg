# A borg client instance
define borg::client (
  String $fqdn,
  String $key,
  String $borg_base = '',
  String $borg_user = '',
){
  if $borg_base == '' or $borg_user == '' {
    fail('borg::client needs $borg_base and $borg_user defined')
  }

  ssh_authorized_key{$name:
      options => ["command=\"cd ${borg_base}; borg serve --restrict-to-repository ${fqdn}\"", 'restrict'],
      user    => $borg_user,
      type    => ed25519,
      key     => $key,
  }
}
