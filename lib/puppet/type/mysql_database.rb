# mysql/lib/puppet/type/mysql_database.rb
#
# Manage MySQL databases as Puppet resources.
#

Puppet::Type.newtype(:mysql_database) do
  @doc = "Manage a MySQL database."

  ensurable

  newparam(:name) do
    desc "The name of the database."

    validate do |value|
      # Check that the name is within the length bounds.
      unless value.length > 0
        raise ArgumentError, "You must specify a name." % value
      end
      unless value.length <= 64
        raise ArgumentError, "%s must be 64 characters or shorter." % value
      end

      # Check that the name is sensible.
      unless value =~ /^\w+/
        raise ArgumentError, "%s is not a valid MySQL database name." % value
      end
      if value =~ /^[0-9]+$/
        raise ArgumentError, "%s is not a valid MySQL database name (it's a number!)" % value
      end
    end #Validate
  end #:name

  newparam(:server) do
    desc "MySQL server to host the database. This should be a Puppet node."

    isrequired

    default = :fqdn
  end #newparam(:server)

end
