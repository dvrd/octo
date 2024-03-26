package octo

USAGE :: `
octo [v0.1.0]

Usage: 

  init  - initialize a project in the current directory
  new	- create a new project
  run   - run current directory project
`

NEW_USAGE :: `Usage: 
  new <name> - create a new project
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
