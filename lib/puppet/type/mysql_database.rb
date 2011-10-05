# This has to be a separate type to enable collecting
Puppet::Type.newtype(:mysql_database) do
  @doc = "Manage creation/deletion of a MySQL database."

  ensurable

  newparam(:name) do
    desc "The name of the database."
    isnamevar
  end
  
  newproperty(:charset) do
    desc "The characterset to use for a database"
    defaultto :utf8
    newvalue(/^\S+$/)
  end

end

