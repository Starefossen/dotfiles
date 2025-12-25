function yta --description "Download audio from YouTube using yt-dlp"
    if test (count $argv) -eq 0
        echo "Usage: yta <url> [title]"
        return 1
    end

    set -l url $argv[1]
    set -l title "%(title)s"

    if test (count $argv) -ge 2
        set title $argv[2]
    end

    yt-dlp -x --audio-format best -o "$title.%(ext)s" $url
end
