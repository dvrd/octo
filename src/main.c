#include "ansi.h"
#include "commands.h"
#include "utils.h"

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
    build_project();

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
