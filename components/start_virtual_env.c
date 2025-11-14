#include "../utils/utils.h"
#include "headers/start_venv.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int start_venv() {
  printf("Starting virtual environment...\n");
  fflush(stdout);
  sleep(1);

#ifdef _WIN32
  int venv_result = system("python -m venv venv");
#else
  int venv_result = system("python3 -m venv venv");
#endif

  if (venv_result != 0) {
    printf("⚠️  Virtual environment could NOT be created. Check Python "
           "install.\n");
    fflush(stdout);
    sleep(1);
    return 1;
  } else {
    printf("Virtual environment is ready.\n");
    fflush(stdout);
    sleep(1);

#ifdef _WIN32
    printf("\nStarting virtual environment...\n");
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
    system("venv\\Scripts\\activate");
    progress_bar(100);
#else
    printf("\nStarting virtual environment...\n");
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
    system("source venv/bin/activate");
    progress_bar(100);
#endif
  }
  return 0;
}
