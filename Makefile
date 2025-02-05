DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard ./dotfiles/.??*)
EXCLUSIONS := %.DS_Store %.git %.gitmodules
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

list: ## Show dot files in this repo
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

update: ## Fetch changes for this repo
	git pull origin master
	git submodule init
	git submodule update
	git submodule foreach git pull origin master

setup-dotfiles: ## Create symlink to home directory
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(notdir $(val));)
	ln -sfnv $(abspath dotfiles/.vimrc) $(HOME)/.ideavimrc
clean-dotfiles: ## Remove symlink from home directory
	@-$(foreach val, $(DOTFILES), rm -vrf $(HOME)/$(notdir $(val));)
	rm -vrf $(HOME)/.ideavimrc

setup-shell: ## Setup shell config installed from brew
	echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
	chsh -s /opt/homebrew/bin/zsh
	curl -Lo install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
	sh install.sh
	rm install.sh
clean-shell: ## Delete shell config installed from brew
	chsh -s /bin/bash
	sudo sed -i -e '/^\/opt\/homebrew/d' /etc/shells
	curl -Lo uninstall.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/uninstall.sh
	sh uninstall.sh
	rm uninstall.sh

setup-brew: Brewfile ## Install packages from Brewfile
	brew bundle
clean-brew: ## Uninstall packages from Brewfile
	brew remove --force $(shell brew list) --ignore-dependencies

setup-vim: ## Download Vim Plugins
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	git clone https://github.com/tomislav/osx-terminal.app-colors-solarized ~/git/tomislave/osx-terminal.app-colors-solarized
clean-vim: ## Download Vim Plugins
	rm -rf ~/.vim/autoload/plug.vim
	rm -rf ~/git/tomislave/osx-terminal.app-colors-solarized

setup-all: setup-brew setup-vim setup-shell setup-dotfiles ## Call all functions setup-***
clean-all: clean-brew clean-vim clean-shell clean-dotfiles ## Call all functions clean-***

install: update setup-all ## Call update and setup-all
	@exec $$SHELL

help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

