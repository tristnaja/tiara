#include "../include/commands/init.h"
#include "../include/commands/new.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#ifndef VERSION
#define VERSION "0.1.0"
#endif

#define AUTHOR "tristan"
#define DESCRIPTION "Tiara — FastAPI project generator"

int main(int argc, char *argv[]) {
  // No args
  if (argc <= 1) {
    printf("Usage: tiara <command> [args]\n");
    printf("Commands:\n");
    printf("  new <name>\n");
    printf("  init <name>\n");
    printf("  --version | -v\n");
    return 1;
  }

  // Version flag
  if (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0) {
    printf("Tiara CLI v%s\n", VERSION);
    printf("Author: %s\n", AUTHOR);
    printf("%s\n", DESCRIPTION);
    return 0;
  }

  // tiara new <project>
  if (strcmp(argv[1], "new") == 0) {
    if (argc != 3) {
      printf("Usage: tiara new <project_name>\n");
      return 1;
    }

    system("clear");
    printf("Creating new FastAPI Project...\n");
    sleep(1);

    if (new_project(argv[2]) != 0) {
      perror("Cannot create new project");
      return 1;
    }
    return 0;
  }

  // tiara init <project>
  if (strcmp(argv[1], "init") == 0) {
    system("clear");
    printf("Initializing FastAPI project...\n");
    fflush(stdout);
    sleep(1);

    printf("Getting current working directory...\n");
    fflush(stdout);
    sleep(1);

    char cwd[512];
    getcwd(cwd, sizeof(cwd));

    char *last = strrchr(cwd, '/');

    printf("%s\n", cwd);
    fflush(stdout);
    sleep(1);

    if (init_project(last) != 0) {
      perror("Cannot initialize project");
      return 1;
    }
    return 0;
  }

  // Unknown command
  printf("Unknown command: %s\n", argv[1]);
  printf("Usage: tiara new <project_name>\n");
  return 1;
}
