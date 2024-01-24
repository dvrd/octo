#ifndef UTILS_H
#define UTILS_H

// IO
void error(const char *msg, const char *error_msg);

// FILES
bool dir_exist(const char *dirname);
bool file_exist(const char *filename);
char *cwd();

// STRINGS
char *concat(const char *s1, const char *s2);

// LOCAL
char *get_project_name();

#include <dirent.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "ansi.h"

inline bool dir_exist(const char *dirname) {
  DIR *dir = opendir(dirname);

  if (dir) {
    closedir(dir);
    return true;
  }

  return false;
}

inline bool file_exist(const char *filename) {
  return access(filename, F_OK) == 0;
}

inline void error(const char *msg, const char *error_msg) {
  fprintf(stderr, AC_RED "error: " AC_NORMAL "%s%s\n", msg, error_msg);
  exit(1);
}

inline char *concat(const char *s1, const char *s2) {
  char *result =
      (char *)malloc(strlen(s1) + strlen(s2) + 1); // +1 for the null-terminator
  if (result == NULL) {
    printf("malloc failed to allocate memory at concat\n");
    exit(0);
  }
  strcpy(result, s1);
  strcat(result, s2);
  return result;
}

inline char *cwd() {
  char filename[256];
  if (getcwd(filename, sizeof(filename)) == NULL) {
    perror("getcwd() error");
    exit(1);
  }
  char *result = (char *)malloc(strlen(filename) + 1);
  strcpy(result, filename);

  return result;
}

inline char *get_project_name() {
  char *proj_name = cwd();
  char *token = strtok(proj_name, "/");
  do {
    proj_name = token;
    token = strtok(NULL, "/");
  } while (token != NULL);
  return proj_name;
}

#endif /* UTILS_H */
