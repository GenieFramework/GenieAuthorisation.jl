module GenieAuthorisation

using Reexport
using Genie
using SearchLight, SearchLight.Relationships
import GeniePlugins
@reexport using GenieAuthentication

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


function assign_role(user::U, role::Role)::Bool where {U<:AbstractModel}
  Relationship!(user, role)

  true
end


function assign_permission(role::Role, permission::Permission) :: Bool
  Relationship!(role, permission)

  true
end


function has_role(user::U, role::Role)::Bool where {U<:AbstractModel}
  isrelated(user, role)
end


function has_role(user::U, role::Union{String,Symbol})::Bool where {U<:AbstractModel}
  has_role(user, findone(Role, name = string(role)))
end


function fetch_permission(permission::Union{Permission,String,Symbol}) :: Union{Permission,Nothing}
  isa(permission, Permission) || (permission = findone(Permission, name = string(permission)))

  permission
end


function has_permission(role::Role, permission::Union{Permission,String,Symbol})::Bool
  permission = fetch_permission(permission)
  permission === nothing && return false
  isrelated(role, permission)
end


function has_permission(user::U, permission::Union{Permission,String,Symbol})::Bool where {U<:AbstractModel}
  permission = fetch_permission(permission)
  permission === nothing && return false
  isrelated(user, permission, through = [Role])
end


function has_permission(u::Nothing, permission)::Bool
  false
end


macro authorised!(permission, exception = Genie.Exceptions.NotFoundException("Page"))
  :(has_permission($(esc( :( Main.UserApp.current_user() ) )), $(esc(permission))) || throw($exception))
end


"""
    install(dest::String; force = false, debug = false) :: Nothing

Copies the plugin's files into the host Genie application.
"""
function install(dest::String; force = false, debug = false) :: Nothing
  # automatically install the GenieAuthentication plugin -- however, do not force the install
  GenieAuthentication.install(dest; force = false, debug = debug)

  src = abspath(normpath(joinpath(pathof(@__MODULE__) |> dirname, "..", Genie.Plugins.FILES_FOLDER)))

  debug && @info "Preparing to install from $src into $dest"
  debug && @info "Found these to install $(readdir(src))"

  for f in readdir(src)
    debug && @info "Processing $(joinpath(src, f))"
    debug && @info "$(isdir(joinpath(src, f)))"

    isdir(joinpath(src, f)) || continue

    debug && "Installing from $(joinpath(src, f))"

    GeniePlugins.install(joinpath(src, f), dest, force = force)
  end

  nothing
end

end
