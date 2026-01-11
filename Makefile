.PHONY: rebase-from-latest-template merge-latest-template track-template-repo customize-template help

.DEFAULT_GOAL := help

help:
	@echo "Available commands:"
	@echo "  make rebase-from-latest-template - Rebase current branch on latest template changes"
	@echo "  make merge-latest-template - Merge latest template changes into current branch"
	@echo "  make track-template-repo - Set up git remote to track template repository"
	@echo "  make customize-template - Customize template with your app name"

rebase-from-latest-template:
	./scripts/rebase-from-latest-template.sh

merge-latest-template:
	./scripts/merge-latest-template.sh

track-template-repo:
	./scripts/track-template-repo.sh

customize-template:
	@scripts/customize-template.sh
