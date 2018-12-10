# pf firewall option builder.
define pf::set(
  Enum['present','absent'] $ensure = 'present',
  Enum['timeout','loginterface','limit','ruleset-optimization',
       'optimization','block-policy','state-policy','state-defaults',
       'hostid','require-order','fingerprints','skip on','debug'] $key = $name,
  String $value,
  Optional[String] $order = '002',
) {

  # Validate some of the values for the option provided...
  case $key {
    'ruleset-optimization': {
      validate_re($value,'^(none|basic|profile)$')
    } 'optimization': {
      validate_re($value,'^(normal|high-latency|aggressive|conservative)$')
    } 'block-policy': {
      validate_re($value,'^(drop|return)$')
    } 'state-policy': {
      validate_re($value,'^(if-bound|floating)$')
    } 'debug': {
      validate_re($value,'^(none|urgent|misc|loud)$')
    } default: {
      #NOOP
    }
  }

  if $order {
    $_order = $order
  } else {
    validate_re($name,'^\d{3} ',
    'pf::set $name must begin with 3 numbers when $order is not specified')
    $rule_split = split($name,' ')
    $_order = $rule_split[0]
  }

  include pf

  if $ensure == 'present' {
    concat::fragment { "pf_set_${name}":
      target  => $pf::rules_file,
      content => template('pf/set.erb'),
      order   => $_order,
    }
  }
}
