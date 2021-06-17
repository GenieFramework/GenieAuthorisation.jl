module CreateTablePermissions

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:permissions) do
    [
      primary_key()
      column(:name, :string, limit = 100)
    ]
  end

  add_index(:permissions, :name)
end

function down()
  drop_table(:permissions)
end

end
