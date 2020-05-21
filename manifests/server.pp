# Set up stuff on the borg server
class borg::server (
  String $user = 'borg',
  String $base_dir = '/var/lib/borg',
  String $export_tag = 'borg',
){
  Borg::Client <<| tag==$export_tag |>> {
    borg_base => $base_dir,
    borg_user => $user,
  }
}
