package octo

REGISTRY_DIR :: ".octo"

USAGE :: `
octo [v0.16.0]

Usage:

  init              - initialize a project in the current directory
  new               - create a new project
  run, r            - build a debug version and run current directory project
  build             - build a debug version of current directory project
  release           - build a release version of current directory project
  install, i        - generate a symlink of your project to /usr/local/bin
  help              - show this message
  add               - add a dependency library to the project
  remove, rm        - remove a dependency library from the project
  update            - git pull rebase one of your dependencies
  list, ls          - list all installed dependencies in the registry directory
`

NEW_USAGE :: `Usage:
  octo new <PKG> - create a new project
`

BUILD_USAGE :: `Usage:
  octo build [--release] - create a new project
`

ADD_USAGE :: `Usage:
  octo add [<SERVER>]/[<OWNER>]/<PKG> - add a dependency library to the project

  NOTE: 
    * octo will always try to search first in the registry
    * If "owner" and "pkg" are provided octo will try in github or OCTO_GIT_SERVER after checking registry
`

REMOVE_USAGE :: `Usage:
  octo remove [<OWNER>]/<PKG> - remove a dependency library from the project
`

SEARCH_USAGE :: `Usage:
  octo search <PKG> - searches the web for a dependency
`

UPDATE_USAGE :: `Usage:
  octo update <PKG> - git pull rebase one of your dependencies
`

OLS_FILE :: "ols.json"
OLS_TEMPLATE :: `
{
    "$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/ols.schema.json",
    "collections": [
        {
            "name": "src",
            "path": "src"
        },
        {
            "name": "libs",
            "path": "libs"
        }
    ],
    "profile": "default",
    "enable_document_symbols": true,
    "enable_semantic_tokens": true,
    "enable_snippets": true,
    "enable_references": true,
    "enable_fake_methods": true,
    "enable_inlay_hints": true,
    "enable_procedure_snippet": true,
    "verbose": true,
    "enable_hover": true
}
`

OCTO_CONFIG_FILE :: "octo.pkg"
OPM_CONFIG_FILE :: "mod.pkg"
OCTO_CONFIG_TEMPLATE :: `{{
    version: "%s",
    name: "%s",
    owner: "%s",
    description: "%s",
    url: "%s",
    readme: "",
    license: "",
    keywords: [],
    dependencies: {{}}
}}`

MAIN_FILE :: "main.odin"
MAIN_TEMPLATE :: `
package %s

import "core:fmt"

main :: proc() {{
    fmt.println("Hello Octo")
}}
`

GITIGNORE_FILE :: ".gitignore"
GITIGNORE_TEMPLATE :: `
target
`
