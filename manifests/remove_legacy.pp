# Remove the old scripts and cron job named just "backup"
class borg::remove_legacy {
  $legacy_files = [
    '/usr/local/sbin/backup',
    '/usr/local/sbin/restore',
    '/etc/cron.daily/backup',
  ]
  file {$legacy_files:
    ensure => absent,
  }
}
