# == Class: cobbler
#
# Installs and configures cobbler-web.  BIND 9 and ISC DHCP can
# also be included with the $manage_dns and $manage_dhcp
# parameters, respectively.
#
# Currently, this module requires a manual "cobbler sync" after
# first being applied.
#
# === Parameters
#
# [*allow_dynamic_settings*]
#   Allows changes to Cobbler's setting file without a restart
#   of cobblerd.
#   Type: Boolean
#   Default: true
#
# [*default_password_crypted*]
#   The default password to use on build machines.
#   Type: String
#   Default: '$1$mF86/UHC$WvcIcX2t6crBz2onWxyac.'
#
# [*manage_dhcp*]
#   If true, Cobbler acts as a DHCP server.
#   Type: Boolean
#   Default: false
#
# [*manage_dns*]
#   If true, Cobbler acts as a DNS server.
#   Type: Boolean
#   Default: false
#
# [*manage_forward_zones*]
#   An array of forward zones to be managed by Cobbler DNS.
#   Requires manage_dns to take effect
#   Type: Array
#   Default: ['example.com', '2.example.com']
#
# [*manage_reverse_zones*]
#   An array of reverse zones to be managed by Cobbler DNS
#   Requires manage_dns to take effect
#   Type: Array
#   Default: ['10.0.0', '192.168.0']
#
# [*next_server*]
#   The Next Server address passed to DHCP clients
#   Type: String
#   Default: $::ipaddress (from Facter)
#
# [*package_version*]
#   The "ensure" parameter for the cobbler-web package
#   Type: String
#   Default: 'installed'
#
# [*serializer_pretty_json*]
#   If true, Cobbler outputs more human-readable JSON
#   files
#   Type: Boolean
#   Default: true
#
# [*server*]
#   The address of the Cobbler server
#   Type: String
#   Default: $::ipaddress (from Facter)
#
# === Variables
#
# These are all parameters.
#
# === Examples
#
#  This will install DHCP and DNS and manage some zones.
#
#  class { 'cobbler':
#    manage_dhcp            => true,
#    manage_dns             => true,
#    manage_forward_zones   => ['some.domain.com', 'another.domain.com'],
#    manage_reverse_zones   => ['10.42.0', '10.42.1'],
#  }
#
# === Authors
#
# Mike Nolte <obiwanmikenolte@gmail.com>
#
# === Copyleft
#
class cobbler (

  $allow_dynamic_settings                = true,
  $default_password_crypted              = '$1$mF86/UHC$WvcIcX2t6crBz2onWxyac.',
  $manage_dhcp                           = false,
  $manage_dns                            = false,
  $manage_forward_zones                  = ['example.com', '2.example.com'],
  $manage_reverse_zones                  = ['10.0.0', '192.168.0'],
  $next_server                           = $::ipaddress,
  $package_version                       = 'installed',
  $puppet_auto_setup                     = false,
  $remove_old_puppet_certs_automatically = false,
  $serializer_pretty_json                = true,
  $server                                = $::ipaddress,
  $sign_puppet_certs_automatically       = false,

) {

  case $::osfamily {
    'RedHat': {
      $apache_service = 'httpd'
      $binary = '/bin/cobbler'
      $dhcp_package = 'dhcp'
      $dhcp_service = 'dhcpd'
      $dns_package = 'bind-chroot'
      $dns_service = 'named'
      $service = 'cobblerd'

      Class['::epel'] -> Package['cobbler-web'] -> Class['::selinux']
      include '::epel'

      package { 'syslinux-tftpboot': }

      package { 'pykickstart': }

    }
    'Debian': {
      $apache_service = 'apache2'
      $binary = '/usr/bin/cobbler'
      $dhcp_package = 'isc-dhcp-server'
      $dhcp_service = $dhcp_package
      $dns_package = 'bind9'
      $dns_service = $dns_package
      $service = 'cobbler'
    }
  }

  include '::firewall'
  include '::selinux'

  selinux::audit2allow { 'cobbler-web':
    source => "puppet:///modules/${module_name}/selinux/messages.cobbler-web",
  }

  selinux::audit2allow { 'cobblerd':
    source => "puppet:///modules/${module_name}/selinux/messages.cobblerd",
  }

  selinux::audit2allow { 'reposync':
    source => "puppet:///modules/${module_name}/selinux/messages.reposync",
  }

  package { 'cobbler-web':
    ensure => $package_version,
  }

  exec { 'cobbler-sync':
    command     => "${binary} sync",
    refreshonly => true,
    require     => Cobbler::Setting['server'],
  }

  service { $service:
    ensure  => running,
    enable  => true,
    require => Package['cobbler-web'],
  }

  service { $apache_service:
    ensure  => running,
    enable  => true,
    require => Package['cobbler-web'],
  }

  firewall { '100 Accept inbound connections to Cobbler web ports':
    dport  => ['80', '443'],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '100 Accept outbound connections from Cobbler web ports':
    chain  => 'OUTPUT',
    dport  => ['80', '443'],
    state => ['ESTABLISHED'],
    proto  => 'tcp',
    action => 'accept',
  }

  if ( $manage_dhcp ) { include cobbler::dhcp }

  if ( $manage_dns ) { include cobbler::dns }

  cobbler::setting { 'allow_dynamic_settings':
    value   => $allow_dynamic_settings,
    notify  => Service[$service],
    require => Cobbler::Setting['server'],
  }

  cobbler::setting { 'manage_dhcp': 
    value   => $manage_dhcp,
    require => Cobbler::Setting['allow_dynamic_settings'],
  }

  cobbler::setting { 'manage_dns': 
    value   => $manage_dhcp,
    require => Cobbler::Setting['allow_dynamic_settings'],
  }

  cobbler::setting { 'default_password_crypted': value => $default_password_crypted }

  cobbler::setting { 'manage_forward_zones': value => $manage_forward_zones }

  cobbler::setting { 'manage_reverse_zones': value => $manage_reverse_zones }

  cobbler::setting { 'puppet_auto_setup': value => $puppet_auto_setup }

  cobbler::setting { 'next_server': value => $next_server }

  cobbler::setting { 'remove_old_puppet_certs_automatically': value => $remove_old_puppet_certs_automatically }

  cobbler::setting { 'serializer_pretty_json': value => $serializer_pretty_json }

  cobbler::setting { 'server': value => $server }

  cobbler::setting { 'sign_puppet_certs_automatically': value => $sign_puppet_certs_automatically }

}
