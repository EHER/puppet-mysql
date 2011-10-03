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

	# Find the existing instances
	def self.instances
		grants = []
		cmd = "#{command(:mysql)} --defaults-file=/etc/mysql/debian.cnf mysql -NBe 'select concat(user, \"@\", host) from user'"
		execpipe(cmd) do |process|
			process.each do |line|
				grants << new( user_line_to_hash(line) )
			end
		end
		cmd = "#{command(:mysql)} --defaults-file=/etc/mysql/debian.cnf mysql -NBe 'select concat(user, \"@\", host, \"/\", db) from db'"
		execpipe(cmd) do |process|
			process.each do |line|
				grants << new( db_line_to_hash(line) )
			end
		end
		
		
		return grants
	end
	def self.user_line_to_hash(line)
		fields = line.chomp.split(/\t/)
		{
			:name => fields[0],
			:ensure => :present
		}
	end
	def self.db_line_to_hash(line)
		fields = line.chomp.split(/\t/)
		{
			:name => fields[0],
			:ensure => :present
		}
	end


	def mysql_flush
		mysqladmin "--defaults-file=/etc/mysql/debian.cnf", "flush-privileges"
	end

	# this parses the
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

	def create_row
		unless @resource.should(:privileges).empty?
			name = split_name(@resource[:name])
			case name[:type]
			when :user
				mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "INSERT INTO user (host, user) VALUES ('%s', '%s')" % [
					name[:host], name[:user],
				]
			when :db
				mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "INSERT INTO db (host, user, db) VALUES ('%s', '%s', '%s')" % [
					name[:host], name[:user], name[:db],
				]
			end
			mysql_flush
		end
	end

	def row_exists?
		name = split_name(@resource[:name])
		fields = [:user, :host]
		if name[:type] == :db
			fields << :db
		end
		not mysql("--defaults-file=/etc/mysql/debian.cnf", "mysql", "-NBe", 'SELECT "1" FROM %s WHERE %s' % [ name[:type], fields.map do |f| "%s = '%s'" % [f, name[f]] end.join(' AND ')]).empty?
	end


	def all_privs_set?
		all_privs = case split_name(@resource[:name])[:type]
			when :user
				MYSQL_USER_PRIVS
			when :db
				MYSQL_DB_PRIVS
		end
		all_privs = all_privs.collect do |p| p.to_s end.sort.join("|")
		privs = privileges.collect do |p| p.to_s end.sort.join("|")

		all_privs == privs
	end

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

		# puts "Setting privs: ", privs.join(", ")
		name = split_name(@resource[:name])
		stmt = ''
		where = ''
		all_privs = []
		case name[:type]
		when :user
			stmt = 'update user set '
			where = ' where user="%s" and host="%s"' % [ name[:user], name[:host] ]
			all_privs = MYSQL_USER_PRIVS
		when :db
			stmt = 'update db set '
			where = ' where user="%s" and host="%s" and db="%s"' % [ name[:user], name[:host], name[:db] ]
			all_privs = MYSQL_DB_PRIVS
		end

		if privs[0] == :all
			privs = all_privs
		end

		# puts "stmt:", stmt
		set = all_privs.collect do |p| "%s = '%s'" % [p, privs.include?(p) ? 'Y' : 'N'] end.join(', ')
		# puts "set:", set
		stmt = stmt << set << where

		mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-NBe", stmt
		mysql_flush
	end
	
	#
	# Create a new resource.
	#
	def create
		create_row
		#mysql_flush
	end
	
	#
	# Destroy a resource
	#
	def destroy
		name = split_name(@resource[:name])

		case name[:type]
		when :user
			mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "DELETE FROM user WHERE host='%s' AND user='%s')" % [
				name[:host], name[:user],
			]
		when :db
			mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "DELETE FROM db WHERE host='%s' AND user='%s' AND db='%s'" % [
				name[:host], name[:user], name[:db],
			]
		end
		mysql_flush
	end
	
	#
	# Check whether a resource exists.
	#
	def exists?
		#stmt = ''
		#when :user
			#stmt = 'SELECT \'1\' FROM user WHERE user="%s" AND host="%s"' % [ name[:user], name[:host] ]
		#when :db
			#stmt = 'SELECT \'1\' FROM db WHERE user="%s" AND host="%s" AND db="%s"' % [ name[:user], name[:host], name[:db] ]
		#end

		#not mysql("--defaults-file=/etc/mysql/debian.cnf", "mysql", "-NBe", stmt).empty?
		
		row_exists?
	end

end

