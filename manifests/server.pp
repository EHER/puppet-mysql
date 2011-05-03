
class mysql::server {
  include mysql::server::package
  include mysql::server::service
}

class mysql::server::package {

  $pkg = $operatingsystem ? {
    debian => "mysql-server-5.1"
  }

  package { $pkg :
    ensure => installed,
  }

}

class mysql::server::service {

  $srv = $operatingsystem ? {
    debian => "mysql"
  }

  service { $srv :
    enable     => true,
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    require    => Class["mysql::server::package"],
  }

}

