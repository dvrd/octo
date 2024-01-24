#ifndef COMMANDS_H
#define COMMANDS_H

void build_project();
void run_init();
void run_new(int argc, char *proj_name);

#include <errno.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "ansi.h"
#include "toml.h"
#include "utils.h"

#define REQUIRED_ARG_ERROR                                                     \
  AC_RED "error: " AC_NORMAL                                                   \
         "the following required arguments were not provided\n" AC_BLUE        \
         "\t<PATH>\n\n" AC_GREEN "Usage: " AC_BLUE                             \
         "octo new <PATH>\n\n" AC_NORMAL
#define DIRECTORY_EXISTS_ERROR                                                 \
  AC_RED "error: " AC_NORMAL "directory already exists\n\n"

#define INIT_SUCCESS_MSG                                                       \
  AC_GREEN "\tCreated " AC_NORMAL "binary (application) `%s` package\n\n"

#define BUILD_SUCCESS_MSG AC_GREEN "\tCompiling " AC_NORMAL "%s v%s (%s)\n"

#define EXIT_SUCCESS 0

#define OPTION_VERSION                                                         \
  AC_BLUE "\t-V, --version" AC_NORMAL "\tPrint version info and exit\n\n"

#define COMMAND_BUILD                                                          \
  AC_BLUE "\tbuild, b" AC_NORMAL "\tCompile the current package\n"
#define COMMAND_RUN                                                            \
  AC_BLUE "\trun, r" AC_NORMAL                                                 \
          "\t\tRun a binary or example of the local package\n"
#define COMMAND_NEW AC_BLUE "\tnew" AC_NORMAL "\t\tCreate a new octo package\n"
#define COMMAND_INIT                                                           \
  AC_BLUE "\tinit" AC_NORMAL                                                   \
          "\t\tInitializes a new octo package in the current directory\n"

inline void build_project() {
  if (!dir_exist("target")) {
    bool error = system("mkdir -p target/debug");
    if (error) {
      exit(1);
    }
  }

  FILE *fp;
  char errbuf[200];

  fp = fopen("Octo.toml", "r");
  if (!fp) {
    error("cannot open sample.toml - ", strerror(errno));
  }

  toml_table_t *conf = toml_parse_file(fp, errbuf, sizeof(errbuf));
  fclose(fp);

  if (!conf) {
    error("cannot parse - ", errbuf);
  }

  toml_table_t *package = toml_table_in(conf, "package");
  if (!package) {
    error("missing [package]", "");
  }

  toml_datum_t name = toml_string_in(package, "name");
  if (!name.ok) {
    error("cannot read package.name", "");
  }

  toml_datum_t version = toml_string_in(package, "version");
  if (!version.ok) {
    error("cannot read package.edition", "");
  }

  toml_datum_t edition = toml_string_in(package, "edition");
  if (!edition.ok) {
    error("cannot read package.edition", "");
  }

  const char *compiler_version =
      strcmp(edition.u.s, "default") == 0 ? "gnu17" : edition.u.s;
  char cmd[128];
  sprintf(cmd, "clang src/*.c -o target/debug/%s -std=%s", name.u.s,
          compiler_version);
  bool error = system(cmd);
  if (error) {
    exit(1);
  }

  printf(BUILD_SUCCESS_MSG, name.u.s, version.u.s, cwd());

  free(name.u.s);
  free(version.u.s);
  free(edition.u.s);

  toml_free(conf);
}

inline void run_init() {
  if (!dir_exist(".git")) {
    bool error = system("git init");
    if (error) {
      exit(1);
    }
  }

  if (!file_exist(".gitignore")) {
    bool error = system("echo '# Added by octo\n\n/target' > .gitignore");
    if (error) {
      exit(1);
    }
  }

  if (!file_exist("Octo.toml")) {
    bool error =
        system("echo '[package]\nname = \"%s\"\nversion = \"0.1.0\"\nedition = "
               "\"default\"\n\n[dependencies]\n' > Octo.toml");
    if (error) {
      exit(1);
    }
  }

  if (!dir_exist("src")) {
    bool error = system("mkdir src");
    if (error) {
      exit(1);
    }
  }

  if (!file_exist("src/main.c")) {
    bool error =
        system("echo '#include <stdio.h>\n\nint main() {\n\tprintf(\"Hello "
               "from C\");\n\treturn 0;\n}' > src/main.c");
    if (error) {
      exit(1);
    }
  }
}

inline void run_new(int argc, char *proj_name) {
  if (argc < 3) {
    fprintf(stderr, REQUIRED_ARG_ERROR);
    exit(1);
  }

  if (dir_exist(proj_name)) {
    fprintf(stderr, DIRECTORY_EXISTS_ERROR);
    exit(1);
  }

  char *cmd = concat("mkdir ", proj_name);
  bool error = system(cmd);
  if (error) {
    exit(1);
  }

  chdir(proj_name);

  error = system("git init > /dev/null");
  if (error) {
    exit(1);
  }

  error = system("echo '# Added by octo\n\n/target' > .gitignore");
  if (error) {
    exit(1);
  }

  error =
      system("echo '[package]\nname = \"%s\"\nversion = \"0.1.0\"\nedition = "
             "\"default\"\n\n[dependencies]\n' > Octo.toml");
  if (error) {
    exit(1);
  }

  error = system("mkdir src");
  if (error) {
    exit(1);
  }

  error = system("echo '#include <stdio.h>\n\nint main() {\n\tprintf(\"Hello "
                 "from C\");\n\treturn 0;\n}' > src/main.c");
  if (error) {
    exit(1);
  }

  free(cmd);
}

#endif /* COMMANDS_H */
