#include "../../include/components/start_pip.h"
#include "../../include/components/clear_screen.h"
#include "../../include/utils/utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

int start_pip() {
  clear_screen();

  printf("Pip Installs...\n");
  fflush(stdout);
  sleep(1);

  system("venv/bin/python3 -m pip install --upgrade pip -q "
         "--disable-pip-version-check");

#ifdef _WIN32
  FILE *pipe = _popen("venv\\Scripts\\pip install -r requirements.txt", "r");
#else
  FILE *pipe = popen("venv/bin/pip install -r requirements.txt", "r");
#endif

  if (!pipe) {
    perror("could not start pip install process");
    return 1;
  }

  char line[521];
  char current_pkg[128] = "";

  while (fgets(line, sizeof(line), pipe)) {
    line[strcspn(line, "\n")] = 0;

    if (sscanf(line, "Collecting %127s", current_pkg) != 0) {
      printf("Fetching %s...\n", current_pkg);
      fflush(stdout);

      continue;
    }

    if (strstr(line, "Installing collected packages:") != NULL) {
      printf("\nInstalling...\n");
      fflush(stdout);

      int progress = 0;
      progress_bar(progress);

      struct timespec last, now;
      clock_gettime(CLOCK_MONOTONIC, &last);

      while (fgets(line, sizeof(line), pipe) != NULL) {
        // check elapsed time
        clock_gettime(CLOCK_MONOTONIC, &now);
        long ms = (now.tv_sec - last.tv_sec) * 1000 +
                  (now.tv_nsec - last.tv_nsec) / 1000000;

        if (ms >= 40 && progress < 100) {
          progress++;
          progress_bar(progress);
          last = now;
        }
      }
      continue;
    }

    if (strncmp(line, "Successfully installed", 21) == 0) {
      printf("Finished: %s\n", line);
    }
  }

#ifdef _WIN32
  int exit_code = _pclose(pipe);
#else
  int exit_code = pclose(pipe);
#endif
  progress_bar(100);
  sleep(1);

  if (exit_code != 0) {
    perror("pip install failed");
  }

  return 0;
}
