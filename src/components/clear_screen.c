#include "../../include/components/clear_screen.h"
#include <stdio.h>

int clear_screen() {
#ifdef _WIN32
  if (system("cls") != 0) {
    printf("\033[2J\033[H"); // fallback for ANSI terminals
  }
#else
  printf("\033[2J\033[H");
#endif
  fflush(stdout);

  return 0;
}
