#include "../utils/utils.h"
#include "headers/clear_screen.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int start_git() {
  clear_screen();
  printf("Initializing Git...\n");
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

  system("git init > /dev/null 2>&1");
  system("git add . > /dev/null 2>&1");
  system("git branch -M main");
  system("git commit -m \"Initial commit\" > /dev/null 2>&1");

  progress_bar(100);

  return 0;
}
