#include "commands/new.c"
#include <_static_assert.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  if (argc != 3) {
    printf("Usage: tiara new project_name\n");
    return 1;
  }

  if (strcmp(argv[1], "new") == 0) {
    char *project_name = argv[2];

    printf("Creating new FastAPI Project...\n");
    fflush(stdout);
    sleep(1);

    if (new_project(project_name) != 0) {
      return 1;
    }
  } else {
    printf("Unknown command: %s\n", argv[1]);
    printf("Usage: tiara new <project_name>\n");
  }
}
