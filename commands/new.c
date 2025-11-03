#include <stdio.h>
#include <sys/stat.h>
#include <unistd.h>

int new_project(char *project_name) {
  if (project_name == NULL) {
    printf("Project Name is not provided.\n The Usage is: tiara new "
           "<project_name>");
    return 1;
  }

  if (mkdir(project_name, 0755) == 0) {
    printf("Successfully created a new project!\n");
    fflush(stdout);
    sleep(1);
    printf("Move to your project with: cd %s\n", project_name);
  } else {
    perror("Failed to create project");
    return 1;
  }

  return 0;
}
