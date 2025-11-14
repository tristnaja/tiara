#include "components/configure_env.h"
#include "utils/utils.h"
#include <stdio.h>
#include <unistd.h>

int configure_env(char *project_name) {
  printf("Configuring .env...\n");
  fflush(stdout);
  sleep(1);

  progress_bar(0);

  for (int i = 0; i <= 95; i++) {
    progress_bar(i);
#ifdef _WIN32
    Sleep(5000);
#else
    usleep(5000);
#endif
  }

  init_env(project_name);

  progress_bar(100);
  return 0;
}
