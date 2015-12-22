class cobbler::dhcp {

  package { $cobbler::dhcp_package: }

  file { '/etc/cobbler/dhcp.template':
    content => template("${module_name}/dhcp.template.erb"),
    require => [ Package[$cobbler::dhcp_package], Cobbler::Setting['manage_dhcp'] ],
    notify  => Exec['cobbler-sync'],
  }

  service { $cobbler::dhcp_service:
    ensure  => running,
    enable  => true,
    require => File['/etc/cobbler/dhcp.template'],
  }

  firewall { '100 Accept inbound connections to Cobbler PXE Ports':
    dport  => ['67', '69'],
    proto  => udp,
    action => accept,
  }

  firewall { '100 Accept outbound connections from Cobbler PXE Ports':
    chain  => 'OUTPUT',
    sport  => ['67', '69'],
    proto  => udp,
    action => accept,
  }

  exec { '/sbin/modprobe nf_conntrack_tftp':
    unless => '/sbin/lsmod | /bin/grep -w ^nf_conntrack_tftp',
  }

}
