function claude_resume -d "Sleep until a given time, show a countdown, and resume Claude"
    set -l auto_mode 0
    set -l target_time ""
    set -l prompt ""

    # 1. Argument Parsing Fix
    if test "$argv[1]" = "--auto"
        set auto_mode 1
        set target_time $argv[2]
        set prompt $argv[3..-1]
    else
        set target_time $argv[1]
        set prompt $argv[2..-1]
    end

    if test -z "$target_time"; or test -z "$prompt"
        echo "Usage: claude_resume [--auto] <HH:MM> <prompt...>"
        echo "Example: claude_resume 14:30 continue the previous task"
        echo "Example: claude_resume --auto 08:00 write tests"
        return 1
    end

    # 2. Variable Scoping Fixes
    set -l target_ts ""
    
    # 3. Portability (Support GNU and BSD date)
    if date --version >/dev/null 2>&1
        # GNU date (Linux)
        set target_ts (date -d "$target_time" +%s 2>/dev/null)
    else
        # BSD date (macOS)
        set target_ts (date -j -f "%H:%M" $target_time +%s 2>/dev/null)
    end

    if test $status -ne 0; or test -z "$target_ts"
        echo "Error: Invalid time format. Please use 24-hour HH:MM format (e.g., 14:30 or 09:00)."
        return 1
    end

    set -l current_ts (date +%s)

    if test $target_ts -le $current_ts
        set target_ts (math "$target_ts + 86400")
    end

    set -l wait_time (math "$target_ts - $current_ts")

    # Start caffeinate in the background for exactly the wait duration
    caffeinate -i -t $wait_time &

    set -l spinner_frames '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'
    set -l i 1

    echo "Timer started. Press Ctrl+C to cancel."

    while test $wait_time -gt 0
        set -l h (math -s0 "$wait_time / 3600")
        set -l m (math -s0 "($wait_time % 3600) / 60")
        set -l s (math -s0 "$wait_time % 60")
        
        printf "\r\033[K%s Waiting until %s... %02d:%02d:%02d remaining" $spinner_frames[$i] $target_time $h $m $s
        
        sleep 1
        set wait_time (math "$wait_time - 1")
        set i (math "$i % 10 + 1")
    end
    
    printf "\r\033[K"
    echo "Time reached! Running Claude..."

    if test $auto_mode -eq 1
        claude -c --dangerously-skip-permissions "$prompt"
    else
        claude -c "$prompt"
    end
end
