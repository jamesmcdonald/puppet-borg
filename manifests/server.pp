# Set up stuff on the borg server
class borg::server {
  Borg::Client <<| tag=='borg-derpy' |>> {
    borg_base => '/tank/backup/borg',
    borg_user => 'borg',
  }
}
