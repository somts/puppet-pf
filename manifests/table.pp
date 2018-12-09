# Define: pf::table
#
# @param class_list A list of class names for which to lookup hosts and return
# the fact_list for addresses.
#
# @param ip_list A list of IP addresses to include in the table.  These values
# are always added to the table.
#
# @param fact_list Alter the data returned during a class lookup as in the case
# when using the class_list param.  This is only used if common_class and
# common_class_param are not used.
#
# @param common_class @param common_class_param
#
define pf::table(
  Enum['present','absent'] $ensure = 'present',
  String $key = $name,
  Array $ip_list = [],
  Optional[String] $order = '003',
) {
  # TODO should class_list be called node_filter?  This might make it easier to
  # filter the nodes that we want, and it looks like a list of classes is still
  # an appropriate use.  Perhaps a rename here would simply make query results
  # more powerful, and perhaps more understandable.

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
    concat::fragment { "pf_table_${name}":
      target  => $pf::rules_file,
      content => template('pf/table.erb'),
    }
  }
}
