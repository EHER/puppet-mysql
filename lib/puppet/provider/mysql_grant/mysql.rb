# mysql/lib/puppet/provider/mysql_grant/mysql.rb
#
# Implement MySQL grant operations for MySQL (as if there's another choice).
#

require 'puppet/provider/package'

MYSQL_USER_PRIVS = [ :select_priv, :insert_priv, :update_priv, :delete_priv,
	:create_priv, :drop_priv, :reload_priv, :shutdown_priv, :process_priv,
	:file_priv, :grant_priv, :references_priv, :index_priv, :alter_priv,
	:show_db_priv, :super_priv, :create_tmp_table_priv, :lock_tables_priv,
	:execute_priv, :repl_slave_priv, :repl_client_priv, :create_view_priv,
	:show_view_priv, :create_routine_priv, :alter_routine_priv,
	:create_user_priv
]

MYSQL_DB_PRIVS = [ :select_priv, :insert_priv, :update_priv, :delete_priv,
	:create_priv, :drop_priv, :grant_priv, :references_priv, :index_priv,
	:alter_priv, :create_tmp_table_priv, :lock_tables_priv, :create_view_priv,
	:show_view_priv, :create_routine_priv, :alter_routine_priv, :execute_priv
]

Puppet::Type.type(:mysql_grant).provide(:mysql, :parent => Puppet::Provider::Package) do

	desc "Uses mysql as database."

	defaultfor :kernel => 'Linux'

	commands :mysql => '/usr/bin/mysql'
	commands :mysqladmin => '/usr/bin/mysqladmin'

	# Find the existing instances of the resource.
	def self.instances
		grants = []
		cmd = "#{command(:mysql)} --defaults-file=/etc/mysql/debian.cnf mysql -Be 'select concat(user, \"@\", host) from user'"
		execpipe(cmd) do |process|
			process.each do |line|
				grants << new( {
					:ensure => :present,
					:name => line.chomp
				} )
			end
		end
		cmd = "#{command(:mysql)} --defaults-file=/etc/mysql/debian.cnf mysql -Be 'select concat(user, \"@\", host, \"/\", db) from db'"
		execpipe(cmd) do |process|
			process.each do |line|
				grants << new( {
					:ensure => :present,
					:name => line.chomp
				} )
			end
		end


		return grants
	end

	# Utility to parse the resource name.
	def split_name(string)
		matches = /^([^@]*)@([^\/]*)(\/(.*))?$/.match(string).captures.compact
		case matches.length
			when 2
				{
					:type => :user,
					:user => matches[0],
					:host => matches[1]
				}
			when 4
				{
					:type => :db,
					:user => matches[0],
					:host => matches[1],
					:db => matches[3]
				}
		end
	end

	# Utility to flush MySQL privileges
	def mysql_flush
		mysqladmin "--defaults-file=/etc/mysql/debian.cnf", "flush-privileges"
	end

	# Check the existance of an instance of the resource.
	def exists?
		fields = split_name(@resource[:name])

		stmt = ""
		case fields[:type]
		when :user
			stmt = "SELECT '1' FROM user WHERE user='%s' AND host='%s'" % [fields[:user], fields[:host]]
		when :db
			stmt = "SELECT '1' FROM db WHERE user='%s' AND host='%s' AND db='%s'" % [fields[:user], fields[:host], fields[:db]]
		end

		not mysql("--defaults-file=/etc/mysql/debian.cnf", "mysql", '-NBe', stmt).empty?
	end

	# Create an instance of the resource.
	def create
		unless exists?
			fields = split_name(@resource[:name])

			stmt = ""
			case fields[:type]
			when :user
				stmt = "INSERT INTO user (user, host) VALUES ('%s', '%s')" % [fields[:user], fields[:host]]
			when :db
				stmt = "INSERT INTO db (user, host, db) VALUES ('%s', '%s', '%s')" % [fields[:user], fields[:host], fields[:db]]
			end

			mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", '-NBe', stmt
		end
	end

	# Destroy an instance of the resource.
	def destroy
		fields = split_name(@resource[:name])

		stmt = ""
		case fields[:type]
		when :user
			stmt = "DELETE FROM user WHERE user='%s' AND host='%s'" % [fields[:user], fields[:host]]
		when :db
			stmt = "DELETE FROM db WHERE user='%s' AND host='%s' AND db='%s'" % [fields[:user], fields[:host], fields[:db]]
		end

		mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", '-NBe', stmt
	end

	# Get the value of the privileges attribute
	def privileges
		name = split_name(@resource[:name])
		privs = ""

		case name[:type]
		when :user
			privs = mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-Be", 'SELECT * FROM user WHERE user="%s" AND host="%s"' % [ name[:user], name[:host] ]
		when :db
			privs = mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-Be", 'SELECT * FROM db WHERE user="%s" AND host="%s" AND db="%s"' % [ name[:user], name[:host], name[:db] ]
		end

		if privs.match(/^$/)
			privs = [] # no result, no privs
		else
			# returns a line with field names and a line with values, each tab-separated
			privs = privs.split(/\n/).map! do |l| l.chomp.split(/\t/) end
			# transpose the lines, so we have key/value pairs
			privs = privs[0].zip(privs[1])
			privs = privs.select do |p| p[0].match(/_priv$/) and p[1] == 'Y' end
		end

		privs.collect do |p| symbolize(p[0].downcase) end
	end

	def privileges=(privs)
		unless row_exists?
			create_row
		end

		name = split_name(@resource[:name])

		stmt = ''
		where = ''
		all_privs = []
		case name[:type]
		when :user
			stmt = 'UPDATE user SET '
			where = ' WHERE user="%s" AND host="%s"' % [ name[:user], name[:host] ]
			all_privs = MYSQL_USER_PRIVS
		when :db
			stmt = 'UPDATE db SET '
			where = ' WHERE user="%s" AND host="%s" AND db="%s"' % [ name[:user], name[:host], name[:db] ]
			all_privs = MYSQL_DB_PRIVS
		end

		if privs[0] == :all
			privs = all_privs
		end

		# puts "stmt:", stmt
		set = all_privs.collect do |p| "%s = '%s'" % [p, privs.include?(p) ? 'Y' : 'N'] end.join(', ')
		# puts "set:", set
		stmt = stmt << set << where

		mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-Be", stmt
		mysql_flush
	end

end

