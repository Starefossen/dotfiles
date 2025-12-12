function check-shai-hulud --description 'Check for Shai-Hulud 2.0 compromised packages in npm/pnpm/yarn lock files'
  # Use provided directory or default to current directory
  set search_dir "."
  if test -n "$argv[1]"
    set search_dir $argv[1]
  end

  # Validate directory exists
  if not test -d $search_dir
    echo "❌ Directory not found: $search_dir" >&2
    return 1
  end

  set ioc_file (mktemp)

  echo "Downloading Shai-Hulud 2.0 IOC list from Wiz Security..."

  if curl -s https://raw.githubusercontent.com/wiz-sec-public/wiz-research-iocs/refs/heads/main/reports/shai-hulud-2-packages.csv | tail -n +2 | cut -f1 -d, > $ioc_file
    echo "Scanning lock files in $search_dir for compromised packages..."
    echo ""

    # Redirect stderr to suppress permission denied errors
    if find $search_dir \( -name package-lock.json -o -name yarn.lock -o -name pnpm-lock.yaml \) -print0 2>/dev/null | xargs -0 grep --color -F -f $ioc_file 2>/dev/null
      echo ""
      echo "⚠️  WARNING: Compromised packages detected!"
      echo "Review the matches above and take immediate action:"
      echo "  1. Rotate all GitHub tokens, npm tokens, and cloud credentials"
      echo "  2. Audit GitHub repos for 'Shai-Hulud' references"
      echo "  3. Check for unexpected public repositories"
      echo "  4. Review GitHub Actions workflows for unauthorized changes"
    else
      echo "✓ No compromised packages found"
    end
  else
    echo "❌ Failed to download IOC list" >&2
    rm -f $ioc_file
    return 1
  end

  rm -f $ioc_file
end
