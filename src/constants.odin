package octo

REGISTRY_DIR :: ".octo"

USAGE :: `
octo [v0.1.0]

Usage:

  init      - initialize a project in the current directory
  new       - create a new project
  run       - build a debug version and run current directory project
  build     - build a debug version of current directory project
  release   - build a release version of current directory project
  install   - generate a symlink of your project to /usr/local/bin
  help      - show this message
  add       - add a dependency library to the project
`

NEW_USAGE :: `Usage:
  new <name> - create a new project
`

ADD_USAGE :: `Usage:
  add <owner>/<pkg> - add a dependency library to the project
`

REMOVE_USAGE :: `Usage:
  remove <owner>/<pkg> - remove a dependency library from the project
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
OCTO_CONFIG_TEMPLATE :: `{{
    name: "%s",
    owner: "%s",
    version: "%s",
    description: "%s",
    url: "https://%s/%s/%s",
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
target/
`
