class cobbler::dns {

  if ( $::osfamily == 'RedHat' ) {
    cobbler::setting { 'bind_chroot':
      value => '/var/named/chroot'
    }
  }

  package { $cobbler::dns_package: }

  file { '/etc/cobbler/named.template':
    content => template("${module_name}/named.template.erb"),
    require => [ Package[$cobbler::dns_package], Cobbler::Setting['manage_dns'] ],
    notify  => Exec['cobbler-sync'],
  }

  service { $cobbler::dns_service:
    ensure  => running,
    enable  => true,
    require => [ File['/etc/cobbler/named.template'] ],
  }

  firewall { '100 Accept inbound connections to Cobbler TCP DNS Port':
    dport  => '53',
    proto  => tcp,
    action => accept,
  }

  firewall { '100 Accept inbound connections to Cobbler UDP DNS Port':
    dport  => '53',
    proto  => udp,
    action => accept,
  }

  firewall { '100 Accept outbound connections from Cobbler DNS Port':
    chain  => 'OUTPUT',
    sport  => '53',
    proto  => tcp,
    action => accept,
  }

}
