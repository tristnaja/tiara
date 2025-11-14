#include "utils/utils.h"
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

void progress_bar(int percent) {
  int width = 50; // bar width

  printf("\r["); // start bracket

  int filled = (percent * width) / 100;
  for (int i = 0; i < width; i++) {
    if (i < filled) {
      printf("█"); // filled block
    } else {
      printf("░"); // empty block
    }
  }

  printf("] %3d%%", percent); // space + percent formatting
  fflush(stdout);

  if (percent == 100) {
    printf("\n");
  }
}

int init_env(char *project_dir) {
  char path[512];
  snprintf(path, sizeof(path), "%s/.env", project_dir);

  FILE *env = fopen(path, "w");

  if (!env) {
    return 1;
  }

  int result = fprintf(
      env, "# Delete The \"#\" when you want to set the Environtment\n"
           "\n# Environtment Variables\n"
           "# DATABASE_URL=mysql+pymysql://username:password@host:port/dbname\n"
           "# SESSION_SECRET=addyoursecret\n"
           "\n# JWT Environtment\n"
           "# JWT_SECRET=addyoursecret\n"
           "# JWT_ALGORITHM=HS256\n"
           "# JWT_EXPIRE_MINUTES=30\n"
           "\n# Google Auth Environtment\n"
           "# GOOGLE_CLIENT_ID=googleclientID\n"
           "# GOOGLE_CLIENT_SECRET=googlesecret\n"
           "# GOOGLE_API_KEY=googleapikey\n"
           "\n# Add more and adjust it as how you need it\n");

  if (result != 0) {
    return 1;
  }

  fclose(env);
  return 0;
}

int safe_mkdir(const char *path) {
  struct stat st = {0};

  if (stat(path, &st) == 0 && !S_ISDIR(st.st_mode)) {
    return 1;
  }

  if (stat(path, &st) == 0) {
    return 0;
  }

  if (mkdir(path, 0755) != 0) {
    return 1;
  }

  return 0;
}

int copy_dir(const char *src, const char *dest) {
  DIR *dir = opendir(src);

  if (!dir) {
    perror("Cannot Open Directory");
    return 1;
  }

  struct dirent *entry;
  char src_path[1024];
  char dest_path[1024];

  safe_mkdir(dest);

  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
      continue;
    }

    snprintf(src_path, sizeof(src_path), "%s/%s", src, entry->d_name);
    snprintf(dest_path, sizeof(dest_path), "%s/%s", dest, entry->d_name);

    struct stat st = {0};
    stat(src_path, &st);

    if (S_ISDIR(st.st_mode)) {
      copy_dir(src_path, dest_path);
    } else {
      FILE *src_file = fopen(src_path, "rb");
      FILE *dest_file = fopen(dest_path, "wb");

      if (!src_file || !dest_file) {
        perror("Failed to open Directory");
        return 1;
      }

      char buffer[4096];
      size_t bytes;
      while ((bytes = fread(buffer, 1, sizeof(buffer), src_file)) > 0) {
        fwrite(buffer, 1, bytes, dest_file);
      }

      fclose(src_file);
      fclose(dest_file);
    }
  }

  closedir(dir);
  return 0;
}
