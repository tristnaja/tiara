#ifndef UTILS_H
#define UTILS_H

void progress_bar(int percent);
int init_env(char *project_dir);
int safe_mkdir(const char *path);
int copy_dir(const char *src, const char *dest);

#endif
