module CreateTablePermissionsRoles

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:permissionsroles) do
    [
      primary_key()
      column(:permissions_id, :int)
      column(:roles_id, :int)
    ]
  end

  add_index(:permissionsroles, :permissions_id)
end

function down()
  drop_table(:permissionsroles)
end

end
