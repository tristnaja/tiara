#include "headers/init.h"
#include "../components/headers/configure_env.h"
#include "../components/headers/start_git.h"
#include "../components/headers/start_pip.h"
#include "../components/headers/start_venv.h"
#include "../utils/utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

int init_project(char *project_name) {
  if (project_name == NULL) {
    printf("Project Name is not provided.\n The Usage is: tiara new "
           "<project_name>\n");
    return 1;
  }

  printf("Initializing the project...\n");
  fflush(stdout);
  sleep(1);

  const char *template_dir = "template/normal/";

  if (copy_dir(template_dir, project_name) == 0) {

    chdir(project_name);

    if (start_venv() != 0) {
      perror("could not start the venv");
      return 1;
    }
    if (start_pip() != 0) {
      perror("could not start the venv");
      return 1;
    }

    if (start_git() != 0) {
      perror("could initiate git");
      return 1;
    }

    chdir("..");

    configure_env(project_name);

    printf("%.*s\n", 40, "----------------------------------------");

    printf("Successfully created a new project!\n");
    fflush(stdout);
    sleep(1);

    printf("Move to your project with: cd %s\n", project_name);
    fflush(stdout);
    sleep(1);
  } else {
    perror("Failed to create project");
    return 1;
  }

  return 0;
}
