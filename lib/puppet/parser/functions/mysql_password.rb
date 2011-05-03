# mysql/lib/puppet/parser/functions/mysql_password.rb
#
# Hash plain-text passwords using the MySQL encryption scheme.
#

# Hash a string like the MySQL "PASSWORD()" function.
require 'digest/sha1'

module Puppet::Parser::Functions
	newfunction(:mysql_password, :type => :rvalue) do |args|
		'*' + Digest::SHA1.hexdigest(Digest::SHA1.digest(args[0])).upcase
	end
end
