# ---------- Project metadata ----------
NAME        := tiara
AUTHOR		:= tristan
VERSION_FILE:= VERSION

# create VERSION if missing (safe)
ifeq ("$(wildcard $(VERSION_FILE))","")
$(shell printf "0.1.0\n" > $(VERSION_FILE))
endif

VERSION     := $(shell cat $(VERSION_FILE))

# ---------- Directories ----------
SRCDIR      := src
INCDIR      := include
OBJDIR      := obj
BINDIR_PROJ := bin

# ---------- Compiler ----------
CC          := gcc
CFLAGS      := -Wall -Wextra -O2 -DVERSION=\"$(VERSION)\" -I$(INCDIR)
LDFLAGS     :=

# list source files
SRC := $(wildcard $(SRCDIR)/*.c) \
       $(wildcard $(SRCDIR)/utils/*.c) \
       $(wildcard $(SRCDIR)/commands/*.c) \
       $(wildcard $(SRCDIR)/components/*.c)

# object files (incremental build in OBJDIR)
OBJS := $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.o,$(SRC))

# final binary
TARGET := $(BINDIR_PROJ)/$(NAME)

# ---------- Install ----------
PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin

# ---------- Tools required ----------
GIT  := $(shell which git 2>/dev/null || true)
GH   := $(shell which gh 2>/dev/null || true)

# ---------- Colors (optional) ----------
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RESET := \033[0m

# ---------- Phony targets ----------
.PHONY: all clean install uninstall help bump patch minor major release changelog rebuild

# ---------- Default ----------
all: $(TARGET)

# link final binary
$(TARGET): $(OBJS)
	@mkdir -p $(@D)
	@printf "$(BLUE)🔧 Linking $(NAME) v$(VERSION)...$(RESET)\n"
	$(CC) $(LDFLAGS) -o $@ $^
	@printf "$(GREEN)✅ Built: $@ (version: %s)$(RESET)\n" "$(VERSION)"

# ---------- Compile rule ----------
# compile each .c → .o (placed in OBJDIR)
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(@D)
	@printf "📦 Compiling $<...\n"
	$(CC) $(CFLAGS) -c -o $@ $<

# ---------- Clean ----------
clean:
	@printf "$(YELLOW)🧹 Cleaning build artifacts...$(RESET)\n"
	-rm -rf $(OBJDIR) $(BINDIR_PROJ)
	@printf "$(GREEN)✔ Cleaned.$(RESET)\n"

# ---------- Install / Uninstall ----------
install: $(TARGET)
	@mkdir -p "$(BINDIR)"
	@dest="$(BINDIR)/$(NAME)"; \
	if [ -f "$$dest" ]; then \
	  printf "♻️  Replacing existing $$dest\n"; \
	  rm -f "$$dest"; \
	fi; \
	cp "$(TARGET)" "$$dest" && chmod 755 "$$dest"; \
	printf "$(GREEN)🚀 Installed to $$dest$(RESET)\n"

uninstall:
	@dest="$(BINDIR)/$(NAME)"; \
	if [ -f "$$dest" ]; then \
	  rm -f "$$dest"; \
	  printf "$(GREEN)🧹 Removed $$dest$(RESET)\n"; \
	else \
	  printf "$(YELLOW)⚠️  $$dest not found (nothing to remove)$(RESET)\n"; \
	fi

# ---------- Version bumping ----------
bump:
	@printf "Current version: $(VERSION)\n"
	@printf "Use 'make patch' or 'make minor' or 'make major'\n"

# patch: increment patch number
patch:
	@old=$$(cat $(VERSION_FILE)); \
	NEW=$$(echo "$$old" | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	printf "$$NEW" > $(VERSION_FILE); \
	printf "$(GREEN)🔧 Patch bump: $$old → $$NEW$(RESET)\n"; \
	$(MAKE) rebuild

# minor: increment minor, reset patch
minor:
	@old=$$(cat $(VERSION_FILE)); \
	NEW=$$(echo "$$old" | awk -F. '{print $$1"."$$2+1".0"}'); \
	printf "$$NEW" > $(VERSION_FILE); \
	printf "$(GREEN)🔧 Minor bump: $$old → $$NEW$(RESET)\n"; \
	$(MAKE) rebuild

# major: increment major, reset minor and patch
major:
	@old=$$(cat $(VERSION_FILE)); \
	NEW=$$(echo "$$old" | awk -F. '{print $$1+1".0.0"}'); \
	printf "$$NEW" > $(VERSION_FILE); \
	printf "$(GREEN)🚀 Major bump: $$old → $$NEW$(RESET)\n"; \
	$(MAKE) rebuild

# rebuild after bump (recompile with new version macro)
rebuild:
	@printf "$(BLUE)♻️  Rebuilding with new version...$(RESET)\n"
	$(MAKE) clean
	$(MAKE) all
	@printf "$(GREEN)✔ Rebuild done. New version: $$(cat $(VERSION_FILE))$(RESET)\n"

# ---------- Changelog (simple) ----------
# Generate CHANGELOG.md from commits since last tag (or all commits if no tag)
changelog:
	@if [ -z "$(GIT)" ]; then \
	  echo "git not found; cannot create changelog"; exit 1; \
	fi
	@last_tag=$$(git describe --tags --abbrev=0 2>/dev/null || true); \
	if [ -z "$$last_tag" ]; then \
	  echo "# Changelog" > CHANGELOG.md; \
	  echo "" >> CHANGELOG.md; \
	  echo "## Unreleased" >> CHANGELOG.md; \
	  git log --pretty=format:"- %s" >> CHANGELOG.md; \
	else \
	  echo "# Changelog" > CHANGELOG.md; \
	  echo "" >> CHANGELOG.md; \
	  echo "## Changes since $$last_tag" >> CHANGELOG.md; \
	  git log $$last_tag..HEAD --pretty=format:"- %s" >> CHANGELOG.md; \
	fi; \
	printf "$(GREEN)✔ Generated CHANGELOG.md$(RESET)\n"

# ---------- Release: commit, tag, push, GitHub release ----------
# requires git; gh CLI optional
release: changelog all
	@if [ -z "$(GIT)" ]; then \
	  echo "git not found; cannot release"; exit 1; \
	fi
	@dirty=$$(git status --porcelain); \
	if [ -n "$$dirty" ]; then \
	  git add -A; \
	  git commit -m "chore(release): prepare release $(VERSION)"; \
	  printf "$(GREEN)✔ Committed changes before release$(RESET)\n"; \
	else \
	  printf "$(YELLOW)ℹ️  Working tree clean (no auto-commit needed)$(RESET)\n"; \
	fi; \
	# create tag
	if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then \
	  printf "$(YELLOW)⚠️  Tag v$(VERSION) already exists. Skipping tag creation.$(RESET)\n"; \
	else \
	  git tag -a "v$(VERSION)" -m "Release v$(VERSION)"; \
	  printf "$(GREEN)🔖 Created tag v$(VERSION)$(RESET)\n"; \
	fi; \
	# push commits and tags
	git push || { printf "$(YELLOW)⚠️  git push failed$(RESET)\n"; exit 1; }; \
	git push --tags || { printf "$(YELLOW)⚠️  git push --tags failed$(RESET)\n"; exit 1; }; \
	printf "$(GREEN)✔ Pushed commits and tags$(RESET)\n"; \
	# attach GitHub release if gh exists
	if [ -n "$(GH)" ]; then \
	  printf "$(BLUE)📦 Creating GitHub release v$(VERSION) (using gh)...$(RESET)\n"; \
	  gh release create "v$(VERSION)" $(TARGET) --notes-file CHANGELOG.md || { printf "$(YELLOW)⚠️  gh release failed or already exists$(RESET)\n"; }; \
	else \
	  printf "$(YELLOW)ℹ️  'gh' CLI not found; skipping GitHub release. Install gh to auto-upload release assets.$(RESET)\n"; \
	fi

# ---------- Help ----------
help:
	@printf "$(BLUE)Usage: make <target>\n\n$(RESET)"
	@printf "Common targets:\n"
	@printf "  all        - build the project (default)\n"
	@printf "  install    - copy binary to $(PREFIX)/bin (default prefix)\n"
	@printf "  uninstall  - remove binary from $(PREFIX)/bin\n"
	@printf "  clean      - remove build artifacts\n"
	@printf "  patch      - bump patch version and rebuild\n"
	@printf "  minor      - bump minor version and rebuild\n"
	@printf "  major      - bump major version and rebuild\n"
	@printf "  bump       - show bump usage\n"
	@printf "  changelog  - generate CHANGELOG.md from git\n"
	@printf "  release    - commit (if needed), tag, push, and GitHub release (if gh installed)\n"
	@printf "\nExamples:\n"
	@printf "  make               # build\n"
	@printf "  make install       # install to $(PREFIX)/bin\n"
	@printf "  make patch         # bump patch & rebuild\n"
	@printf "  make release       # generate changelog, tag & push\n\n"
