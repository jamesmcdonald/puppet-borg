# A borg client instance
define borg::client (
  $fqdn,
  $key,
  $borg_base,
  $borg_user,
){
  ssh_authorized_key{$name:
      options => ["command=\"cd ${borg_base}; borg serve --restrict-to-repository ${fqdn}\"", 'restrict'],
      user    => $borg_user,
      type    => ed25519,
      key     => $key,
  }
}
