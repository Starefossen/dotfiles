#!/usr/bin/env fish

function gh-update -d "Update gh to latest version"
  set ghVersion (curl -v https://api.github.com/repos/cli/cli/releases/latest | jq -r '.tag_name' | cut -c2-)
  echo "Updating to version $ghVersion..."
  curl -vOL "https://github.com/cli/cli/releases/download/v"$ghVersion"/gh_"$ghVersion"_macOS_amd64.tar.gz"
  tar vxf "gh_"$ghVersion"_macOS_amd64.tar.gz"
  sudo mv "gh_"$ghVersion"_macOS_amd64/bin/gh" /usr/local/bin/
  rm -vrf "gh_"$ghVersion"_macOS_amd64*"
end
