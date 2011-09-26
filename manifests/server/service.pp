class mysql::server::service (
	$service = $mysql::params::server_services
) inherits mysql::params {

	service { $service :
		enable     => true,
		ensure     => running,
		hasrestart => true,
		hasstatus  => true,
	}

	Class['mysql::server::configure'] -> Class['mysql::server::service']
	Class['mysql::server::configure'] ~> Class['mysql::server::service']
}

