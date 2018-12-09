# private class to manage pf configuration
class pf::service {
  include pf

  service { 'pf':
    name   => $pf::service_name,
    ensure => $pf::service_ensure,
    enable => $pf::service_enable,
    notify => Exec['pfctl_update'],
  }

  # pfctl does the real work of (re)loading our config; the service
  # simply needs to be running.
  exec { 'pfctl_update':
    command     => "pfctl -f ${pf::conf}",
    refreshonly => true,
    path        => ['/sbin','/bin','/usr/sbin','/usr/bin'],
    subscribe   => Class['pf::config'],
  }
}
