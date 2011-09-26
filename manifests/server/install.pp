class mysql::server::install (
	$packages = $mysql::params::server_packages,
) inherits mysql::params {

	package { $packages :
		ensure => installed,
	}
}
