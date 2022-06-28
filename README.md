# GenieAuthorisation

Role Based Authorisation (RBA) plugin for `Genie.jl`

## Installation

The `GenieAuthorisation.jl` package is a role based authorisation plugin for `Genie.jl`, the highly productive Julia web framework.
As such, it requires installation within the environment of a `Genie.jl` MVC application, allowing the plugin to install
its files.

### Configuring authentication before using authorisation

`GenieAuthorisation.jl` works in tandem with `GenieAuthentication.jl`, the authentication plugin for `Genie.jl` apps.
In fact, `GenieAuthorisation.jl` adds an authorisation layer on top of the authentication features provided by `GenieAuthentication.jl`.
As such, first, please make sure that `GenieAuthentication.jl` is configured for your `Genie.jl` application, following the
instructions at: <https://github.com/GenieFramework/GenieAuthentication.jl>

With the `GenieAuthentication.jl` plugin installed, make sure you configure authenticated access to the areas you want to
further protect with role based authorisation. So the first step is to add user authentication to the app. Then refine access via
authorisation.

### Add the plugin

Now that your application supports user authentication, it's time to add user authorisation.

First, add the plugin (make sure you are in the environment of the `Genie.jl` app you want to protect with autorisation):

```julia
julia> ]

(MyGenieApp) pkg> add GenieAuthorisation
```

Once added, we can use its `install` function to add its files to the `Genie.jl` app (required only upon installation):

```julia
julia> using GenieAuthorisation

julia> GenieAuthorisation.install(@__DIR__)
```

The above command will set up the plugin's files within your `Genie.jl` app (will potentially add new views, controllers, models, migrations, initializers, etc).

## Usage

The bulk of the authorisation features are provided by the package itself together with a series of database migrations which
set up the database tables needed to configure the RBA system.

### Set up the database

The plugin needs DB support to store its configuration (roles, permissions and various relations).
You will find 4 new migration files within the `db/migrations/` folder. We need to run then, either by running all the migrations:

```julia
julia> using SearchLight

julia> SearchLight.Migration.all_up!!()
```

Or by individually running the 4 migrations:

```julia
julia> using SearchLight

julia> SearchLight.Migration.up("CreateTableRoles")
julia> SearchLight.Migration.up("CreateTablePermissions")
julia> SearchLight.Migration.up("CreateTableRolesUsers")
julia> SearchLight.Migration.up("CreateTablePermissionsRoles")
```

This will create all the necessary table.

### Users, roles, and permissions

A role based authorisation system implements access control through permissions. That is, certain features are accessible
only for users that have the necessary permission. For instance, this is how we require authorisation for a `user_admin` permission
at route level:

```julia
route("/admin/users") do; @authorised!("users_admin")
  # code can be accessed only by users with the `users_admin` permission
end
```

Permissions, however, are not assigned directly to users, but to roles. As such, a role can have multiple permissions - like
for example an `admin` role would have all the possible permissions. Finally, the users are assigned roles - getting access
to the role's respective permissions. A role can have any number of permissions and a user can have any number of roles.

`GenieAuthorisation.jl` exposes an API which makes checking users permissions straightforward, without needing to handle
the actual roles. However, the roles make permission assignment manageable: we bundle permissions
into roles and then assign the roles to the users. This way, when we need to remove permissions from a user, we just
remove the role and eliminate the risk of failing to remove all the forbidden permissions.

#### Creating permissions and roles

Given that permissions and roles are stored in the database, we use `SearchLight.jl` to manage the data:

```julia
using GenieAuthorisation

# Create two roles, "user" and "admin"
for r in ["user", "admin"]
  findone_or_create(Role, name = r) |> save!
end

# Create some permissions
for p in ["create", "read", "update", "delete"]
  findone_or_create(Permission, name = p) |> save!
end
```

Now that the roles and the permissions are created, we need to assign permissions to roles:

```julia
using GenieAuthorisation

assign_permission(findone(Role, name = "admin"), findone(Permission, name = "create"))
assign_permission(findone(Role, name = "admin"), findone(Permission, name = "read"))
assign_permission(findone(Role, name = "admin"), findone(Permission, name = "update"))
assign_permission(findone(Role, name = "admin"), findone(Permission, name = "delete"))

assign_permission(findone(Role, name = "user"), findone(Permission, name = "read"))
```

We have assigned "create", "read", "update" and "delete" permissions to the `admin` role, and "read" permissions to the
`user` role.

Now we need to assign roles to our users -- for example making the user with the username `essenciary` an "admin":

```julia
using GenieAuthorisation, GenieAuthentication, Users

assign_role(findone(User, username = "essenciary"), findone(Role, name = "admin"))
```

---
**HEADS UP**

Users must be explicitly assigned roles in order to have any permissions.
Permissions are made available only through roles and this means that users without a role do not have any kind of permissions.

It makes sense to automate role assignment, for example by assigning a default basic role upon user registration.

---

### Autorising access

Once we have permissions, roles, and users, and we have defined the relationships between them, we can enforce user
authorisation within the app.

#### `@authorised!(<permission>)`

The `@authorised!` macro checks that the current user has the `<permission>` permission - if not, an exception is automatically
thrown, stopping the current thread of execution:

```julia
using GenieAuthorisation

route("/admin/users/delete/:user_id") do; @authorised!("delete")
  # code can be accessed only by users with the `users_admin` permission
end
```

#### `has_permission(<user>, <permission>)

We can also use the `has_permission` function to check if a user has the necessary permissions. The function returns a
`boolean` allowing us to implement conditional logic based on the status of the authorisation:

```julia
<% if has_permission(current_user(), "update") || has_permission(current_user(), "delete") %>
<li class="nav-item dropdown">
  <a class="nav-link dropdown-toggle" href="#" data-toggle="dropdown">User management</a>
    <div class="dropdown-menu">

      <% if has_permission(current_user(), "update") %>
      <a class="dropdown-item" href="/admin/users/edit/:user_id">Edit user</a>
      <% end %>

      <% if has_permission(current_user(), "delete") %>
      <a class="dropdown-item" href="/admin/users/delete/:user_id">Delete user</a>
      <% end %>
    </div>
</li>
<% end %>
```

### Deleting authorisation

Deleting authorisation is done by removing the relationships stored in the database, using the `SearchLight.jl` API.

For example, to remove a permission from a role:

```julia
using SearchLight, GenieAuthorisation

Relationship!(findone(Role, name = "admin"), findone(Permission, name = "delete")) |> delete
```

Or a role from a user:

```julia
using SearchLight, GenieAuthorisation, GenieAuthentication, Users

Relationship!(findone(User, username = "essenciary"), findone(Role, name = "admin")) |> delete
```

Finally, to remove roles or permissions, we delete the respective entities:

```julia
using SearchLight, GenieAuthorisation

# remove the `delete` permission
delete(findone(Permission, name = "delete"))

# remove the `admin` role
delete(findone(Role, name = "admin"))
```
