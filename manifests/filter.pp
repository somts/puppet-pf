# pf firewall rule builder that mimics basic firewall{ } type
# parameters where practical.
define pf::filter(
  Enum['present','absent'] $ensure = 'present',
  Enum['accept','drop','reject'] $action = 'accept',
  Enum['INPUT','OUTPUT'] $chain = 'INPUT',
  Enum['tcp','udp','icmp','ipv6-icmp','esp','ah','vrrp','igmp','ipencap',
       'ospf','gre','cbt','all'] $proto = 'tcp',
  Boolean $log = false,
  Boolean $keep_state = true,
  Boolean $quick = true,
  String $destination = 'any',
  String $source = 'any',
  Optional[Variant[String,Integer]] $dport = undef,
  Optional[Variant[String,Integer]] $sport = undef,
  Optional[String] $iniface = undef,
  Optional[String] $outiface = undef,
  Optional[Variant[String,Array]] $flags = undef,
  Optional[Variant[String,Array]] $icmp_type = undef,
) {
  validate_re($name,'^\d{3} ','pf::filter $name must begin with 3 numbers')

  # Map iptables-style parameters to pf-style ones.
  $rule_split = split($name,' ')
  $order = $rule_split[0]
  $_action = $action ? {
    'accept' => 'pass',
    'drop'   => 'block',
    'reject' => $proto ? {
      'tcp'   => 'block return-rst',
      default => 'block return-icmp(net-unr)',
    },
  }
  $_keep_state = $action ? { 'accept' => $keep_state, default  => false }

  # Automatically figure out what 'chain' to use if we're calling an
  # interface.
  $_chain = $iniface ? {
    default => 'in',
    undef   => $outiface ? {
      default => 'out',
      undef   => $chain ? { 'INPUT' => 'in', 'OUTPUT' => 'out' },
    },
  }

  include pf

  if $ensure == 'present' {
    concat::fragment { "pf_filter_${name}":
      target  => $pf::rules_file,
      content => template('pf/filter.erb'),
      order   => $order,
    }
  }
}
