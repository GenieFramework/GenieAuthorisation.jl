using Documenter

push!(LOAD_PATH,  "../../src")

using GenieAuthorisation

makedocs(
    sitename = "GenieAuthorisation - User Authorisation for Genie",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "GenieAuthorisation API" => [
          "GenieAuthorisation" => "API/genieauthorisation.md",
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/GenieAuthorisation.jl.git",
)
