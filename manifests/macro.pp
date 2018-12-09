# This define creates a pf macro with a given key and string value
#
# @param $key The variable name of of the macro
# @param $value The value of the macro to store at the variable
define pf::macro(
  Enum['present','absent'] $ensure = 'present',
  String $value,
  String $key = $name,
  Optional[String] $order = '002',
) {
  include pf

  if $order {
    $_order = $order
  } else {
    validate_re($name,'^\d{3} ',
    'pf::option $name must begin with 3 numbers when $order is not specified')
    $rule_split = split($name,' ')
    $_order = $rule_split[0]
  }

  if $ensure == 'present' {
    concat::fragment { "pf_macro_${name}":
      target  => $pf::rules_file,
      content => "${key} = ${value}\n",
      order   => $_order,
    }
  }
}
