# private class to manage pf configuration
class pf::config {
  include pf

  concat { $pf::rules_file :
    owner          => $pf::owner,
    group          => $pf::group,
    mode           => '0644',
    warn           => "# Managed by Puppet ${name}.",
    ensure_newline => true,
  }

  # Per https://pleiades.ucsc.edu/hyades/PF_on_Mac_OS_X, we get out of
  # the way of OS X defaults for pf by using a custom anchor point.
  if undef != $pf::service_anchor {
    create_resources('file',{
      # Track changes to OS X's service file but don't manage content
      '/System/Library/LaunchDaemons/com.apple.pfctl.plist' => {},
      $pf::conf                                             => {},
      $pf::anchors_d                                        => {
        ensure => 'directory',
        mode   => '0755',
        before => Concat[$pf::rules_file],
      },
      # Establish a parallel service file to OS X's default
      "/Library/LaunchDaemons/${pf::service_name}.plist"    => {
        content => template('pf/darwin/pfctl.plist.erb'),
      },
    },{
      ensure => 'file',
      owner  => $pf::owner,
      group  => $pf::group,
      mode   => '0644',
    })

    # inject our namespace anchor point into pf.conf
    create_resources('file_line', {
      'pf.conf comment'         => {
        line => "# ${pf::service_anchor} anchor point",
      },
      'pf.conf scrub-anchor'    => {
        after => "# ${pf::service_anchor} anchor point",
        line  => "scrub-anchor \"${pf::service_anchor}/*\"",
      },
      'pf.conf nat-anchor'      => {
        after => "scrub-anchor \"${pf::service_anchor}/*\"",
        line  => "nat-anchor \"${pf::service_anchor}/*\"",
      },
      'pf.conf rdr-anchor'      => {
        after => "nat-anchor \"${pf::service_anchor}/*\"",
        line  => "rdr-anchor \"${pf::service_anchor}/*\"",
      },
      'pf.conf dummynet-anchor' => {
        after => "rdr-anchor \"${pf::service_anchor}/*\"",
        line  => "dummynet-anchor \"${pf::service_anchor}/*\"",
      },
      'pf.conf anchor'          => {
        after => "dummynet-anchor \"${pf::service_anchor}/*\"",
        line  => "anchor \"${pf::service_anchor}/*\"",
      },
      'pf.conf load anchor'     => {
        after => "anchor \"${pf::service_anchor}/*\"",
        line  =>
        "load anchor \"${pf::service_anchor}\" from \"${pf::rules_file}\"",
      },
    },{
      path    => $pf::conf,
      require => [File[$pf::conf],Concat[$pf::rules_file]],
    })
  }
}
