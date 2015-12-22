define cobbler::setting ($setting = $name, $value) {
  if ( is_bool($value) ) {
    if $value { $actual_value = 1 }
    else { $actual_value = 0 }
  }
  else { $actual_value = $value }

  yaml_setting { $setting:
   target  => '/etc/cobbler/settings',
   key     => $setting,
   value   => $actual_value,
   notify  => Service[$cobbler::service],
   require => Package['cobbler-web'],
  }
}
