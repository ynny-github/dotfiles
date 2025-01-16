function dump-brew
  rm -f ~/.Brewfile
  brew bundle dump --global
  sed -i '' '/^vscode/d' ~/.Brewfile
end
