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
TEMPLATES_DIR := $(PREFIX)/share/$(NAME)/templates

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
	@printf "$(BLUE)🚀 Installing $(NAME) v$(VERSION)...$(RESET)\n"
	@mkdir -p "$(BINDIR)"
	@mkdir -p "$(TEMPLATES_DIR)"

	# Install binary
	@dest="$(BINDIR)/$(NAME)"; \
	if [ -f "$$dest" ]; then \
	  printf "♻️  Updating existing binary at $$dest\n"; \
	  rm -f "$$dest"; \
	fi; \
	cp "$(TARGET)" "$$dest" && chmod 755 "$$dest"; \
	printf "$(GREEN)✔ Installed binary to $$dest$(RESET)\n"

	# Install / Update templates
	@printf "$(BLUE)📦 Syncing templates...$(RESET)\n"
	@cp -r template/* "$(TEMPLATES_DIR)"/
	@printf "$(GREEN)✔ Templates installed to: $(TEMPLATES_DIR)$(RESET)\n"


uninstall:
	@printf "$(YELLOW)🧹 Uninstalling $(NAME)...$(RESET)\n"
	@dest="$(BINDIR)/$(NAME)"; \
	if [ -f "$$dest" ]; then \
	  rm -f "$$dest"; \
	  printf "$(GREEN)✔ Removed binary $$dest$(RESET)\n"; \
	else \
	  printf "$(YELLOW)⚠️  Binary not found: $$dest$(RESET)\n"; \
	fi

	@if [ -d "$(TEMPLATES_DIR)" ]; then \
	  rm -rf "$(TEMPLATES_DIR)"; \
	  printf "$(GREEN)✔ Removed templates at $(TEMPLATES_DIR)$(RESET)\n"; \
	else \
	  printf "$(YELLOW)⚠️  Templates not found at $(TEMPLATES_DIR)$(RESET)\n"; \
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

# ---------- Changelog (structured) ----------
# Generate CHANGELOG.md from commits since last tag, grouped by type
changelog:
	@if [ -z "$(GIT)" ]; then \
	  echo "git not found; cannot create changelog"; exit 1; \
	fi; \
	last_tag=$$(git describe --tags --abbrev=0 2>/dev/null || true); \
	if [ -z "$$last_tag" ]; then \
	  log_range=""; \
	  title="## Unreleased"; \
	else \
	  log_range="$$last_tag..HEAD"; \
	  title="## Changes since $$last_tag"; \
	fi; \
	printf "# Changelog\n\n" > CHANGELOG.md; \
	printf "$$title\n\n" >> CHANGELOG.md; \
	full_log=$$(git log $$log_range --pretty=format:"%s" --no-merges); \
	changelog_body=""; \
	if [ -n "$$full_log" ]; then \
	  features=$$(printf "%s\n" "$$full_log" | grep "^feat" | sed 's/^feat[^:]*:/ -/' | sort -u); \
	  if [ -n "$$features" ]; then \
	    changelog_body="$${changelog_body}### ✨ Features\n$$features\n\n"; \
	  fi; \
	  fixes=$$(printf "%s\n" "$$full_log" | grep "^fix" | sed 's/^fix[^:]*:/ -/' | sort -u); \
	  if [ -n "$$fixes" ]; then \
	    changelog_body="$${changelog_body}### 🐛 Fixes\n$$fixes\n\n"; \
	  fi; \
	  refactors=$$(printf "%s\n" "$$full_log" | grep "^refactor" | sed 's/^refactor[^:]*:/ -/' | sort -u); \
	  if [ -n "$$refactors" ]; then \
	    changelog_body="$${changelog_body}### ♻️ Refactoring\n$$refactors\n\n"; \
	  fi; \
	  chores=$$(printf "%s\n" "$$full_log" | grep "^chore" | grep -v "chore(release)" | sed 's/^chore[^:]*:/ -/' | sort -u); \
	  if [ -n "$$chores" ]; then \
	    changelog_body="$${changelog_body}### 🔃 Chores\n$$chores\n\n"; \
	  fi; \
	  misc=$$(printf "%s\n" "$$full_log" | grep -vE "^(feat|fix|refactor|chore|docs|style|test|build|ci)" | sed 's/^/ - /' | sort -u); \
	  if [ -n "$$misc" ]; then \
	    changelog_body="$${changelog_body}### Miscellaneous\n$$misc\n\n"; \
	  fi; \
	fi; \
	printf "%b" "$$changelog_body" >> CHANGELOG.md; \
	printf "$(GREEN)✔ Generated CHANGELOG.md$(RESET)\n"

# ---------- Release: commit, tag, push, GitHub release ----------
# requires git; gh CLI optional
release: all
	@if [ -z "$(GIT)" ]; then \
	  echo "git not found; cannot release"; exit 1; \
	fi
	# 1. Generate changelog
	@$(MAKE) changelog
	# 2. Commit version bump and changelog
	git add $(VERSION_FILE) CHANGELOG.md
	git commit -m "chore(release): release $(VERSION)"
	printf "$(GREEN)✔ Committed release v$(VERSION)$(RESET)\n";
	# 3. Create tag
	if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then \
	  printf "$(YELLOW)⚠️  Tag v$(VERSION) already exists. Skipping tag creation.$(RESET)\n"; \
	else \
	  git tag -a "v$(VERSION)" -m "Release v$(VERSION)"; \
	  printf "$(GREEN)🔖 Created tag v$(VERSION)$(RESET)\n"; \
	fi; \
	# 4. Push commits and tags
	git push || { printf "$(YELLOW)⚠️  git push failed$(RESET)\n"; exit 1; }; \
	git push --tags || { printf "$(YELLOW)⚠️  git push --tags failed$(RESET)\n"; exit 1; }; \
	printf "$(GREEN)✔ Pushed commits and tags$(RESET)\n"; \
	# 5. Attach GitHub release if gh exists
	if [ -n "$(GH)" ]; then \
	  printf "$(BLUE)📦 Creating GitHub release v$(VERSION) (using gh)...$(RESET)\n"; \
	  gh release create "v$(VERSION)" --notes-file CHANGELOG.md || { printf "$(YELLOW)⚠️  gh release failed or already exists$(RESET)\n"; }; \
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
