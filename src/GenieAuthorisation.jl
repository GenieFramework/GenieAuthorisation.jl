module GenieAuthorisation

using Genie
using SearchLight, SearchLight.Relationships
using GenieAuthentication

export Role, Permission
export assign_role, assign_permission
export has_role, has_permission, @authorised!

struct UnexpectedTypeException <: Exception
  expected_type::String
  received_type::String
end

struct UndefinedPermissionException <: Exception
  permission::String
end

Base.@kwdef mutable struct Role <: AbstractModel
  id::DbId = DbId()
  name::String = ""
end
Role(name::Union{String,Symbol}) = Role(name = string(name))

Base.@kwdef mutable struct Permission <: AbstractModel
  id::DbId = DbId()
  name::String = ""
end
Permission(name::Union{String,Symbol}) = Permission(name = string(name))


function isusertype(model::M)::Bool where {M<:AbstractModel}
  split(string(typeof(model)), '.')[end] == "User"
end


function assert_user_type(model::M)::Bool where {M<:AbstractModel}
  isusertype(model) || throw(UnexpectedTypeException("User", string(typeof(model))))

  true
end


function assign_role(user::U, role::Role)::Bool where {U<:AbstractModel}
  assert_user_type(user) && Relationship!(user, role)

  true
end


function assign_permission(role::Role, permission::Permission)::Bool
  Relationship!(role, permission)

  true
end


function has_role(user::U, role::Role)::Bool where {U<:AbstractModel}
  assert_user_type(user) && isrelated(user, role)
end


function has_permission(role::Role, permission::Permission)::Bool
  isrelated(role, permission)
end


function has_permission(user::U, permission::Permission)::Bool where {U<:AbstractModel}
  assert_user_type(user) && isrelated(user, permission, through = [Role])
end


macro authorised!(user, permission::Permission, exception = Genie.Exceptions.NotFoundException())
  :(has_permission($user, $permission) || throw($exception))
end



"""
    install(dest::String; force = false, debug = false) :: Nothing

Copies the plugin's files into the host Genie application.
"""
function install(dest::String; force = false, debug = false) :: Nothing
  src = abspath(normpath(joinpath(pathof(@__MODULE__) |> dirname, "..", Genie.Plugins.FILES_FOLDER)))

  debug && @info "Preparing to install from $src into $dest"
  debug && @info "Found these to install $(readdir(src))"

  for f in readdir(src)
    debug && @info "Processing $(joinpath(src, f))"
    debug && @info "$(isdir(joinpath(src, f)))"

    isdir(joinpath(src, f)) || continue

    debug && "Installing from $(joinpath(src, f))"

    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end

  nothing
end

end
