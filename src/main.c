#include "toml.h"
#include <dirent.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define AC_BLACK "\x1b[30m"
#define AC_RED "\x1b[31m"
#define AC_GREEN "\x1b[1;38;2;7;255;113m"
#define AC_YELLOW "\x1b[33m"
#define AC_BLUE "\x1b[1;38;2;125;186;255m"
#define AC_MAGENTA "\x1b[35m"
#define AC_CYAN "\x1b[36m"
#define AC_WHITE "\x1b[37m"
#define AC_NORMAL "\x1b[m"
#define AC_BOLD "\x1b[1m"

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

bool dir_exist(const char *dirname) {
  DIR *dir = opendir(dirname);

  if (dir) {
    closedir(dir);
    return true;
  }

  return false;
}

bool file_exist(const char *filename) { return access(filename, F_OK) == 0; }

static void error(const char *msg, const char *error_msg) {
  fprintf(stderr, AC_RED "error: " AC_NORMAL "%s%s\n", msg, error_msg);
  exit(1);
}

char *concat(const char *s1, const char *s2) {
  char *result =
      malloc(strlen(s1) + strlen(s2) + 1); // +1 for the null-terminator
  if (result == NULL) {
    printf("malloc failed to allocate memory at concat\n");
    exit(0);
  }
  strcpy(result, s1);
  strcat(result, s2);
  return result;
}

char *cwd() {
  char filename[256];
  if (getcwd(filename, sizeof(filename)) == NULL) {
    perror("getcwd() error");
    exit(1);
  }
  char *result = malloc(strlen(filename) + 1);
  strcpy(result, filename);

  return result;
}

char *get_project_name() {
  char *proj_name = cwd();
  char *token = strtok(proj_name, "/");
  do {
    proj_name = token;
    token = strtok(NULL, "/");
  } while (token != NULL);
  return proj_name;
}

void build_project();
void run_init();
void run_new(int argc, char *proj_name);

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "C's package manager\n\n");
    fprintf(stderr, AC_GREEN "Usage: " AC_BLUE "octo [OPTIONS] [COMMANDS]\n\n");
    fprintf(stderr, AC_GREEN "Options: \n" OPTION_VERSION);
    fprintf(stderr, AC_GREEN
            "Commands: \n" COMMAND_BUILD COMMAND_RUN COMMAND_NEW COMMAND_INIT);

    exit(1);
  }

  bool isBuildCommand = strcmp(argv[1], "build") == 0 || argv[1][0] == 'b';
  bool isRunCommand = strcmp(argv[1], "run") == 0 || argv[1][0] == 'r';
  bool isNewCommand = strcmp(argv[1], "new") == 0;
  bool isInitCommand = strcmp(argv[1], "init") == 0;

  if (isInitCommand) {
    char *proj_name = get_project_name();
    run_init();
    printf(INIT_SUCCESS_MSG, proj_name);
    return EXIT_SUCCESS;
  }

  if (isNewCommand) {
    char *proj_name = argv[2];
    run_new(argc, proj_name);
    printf(INIT_SUCCESS_MSG, proj_name);
    return EXIT_SUCCESS;
  }

  if (isBuildCommand) {
    build_project();
    return EXIT_SUCCESS;
  }

  if (isRunCommand) {
    if (!dir_exist("target")) {
      build_project();
    }

    char cmd[128];
    sprintf(cmd, "./target/debug/%s", get_project_name());
    bool error = system(cmd);
    if (error) {
      exit(1);
    }

    return EXIT_SUCCESS;
  }

  return EXIT_SUCCESS;
}

void build_project() {
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

  char *compiler_version =
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

void run_init() {
  if (!dir_exist(".git")) {
    bool error = system("git init");
    if (error) {
      exit(1);
    }
  }

  if (!file_exist(".gitignore")) {
    bool error = system("echo '/bin' > .gitignore");
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

void run_new(int argc, char *proj_name) {
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

  error = system("echo '/bin' > .gitignore");
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
