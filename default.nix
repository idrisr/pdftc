{ writeShellApplication, pdftk, ripgrep, gnused, coreutils }:
writeShellApplication {
  runtimeInputs = [ pdftk ripgrep gnused coreutils ];
  name = "pdftc";

  text = ''
    set -euo pipefail

    cache_version="1"
    cache_enabled=1
    cache_clear=0
    cache_clear_all=0
    cache_info=0
    cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/pdftc"
    pdf=""

    usage() {
        echo "$0 [--no-cache] [--cache-dir PATH] [--cache-clear] [--cache-clear-all] [--cache-info] <pdf file>"
        exit 1
    }

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --no-cache)
                cache_enabled=0
                shift
                ;;
            --cache-dir)
                if [ "$#" -lt 2 ]; then
                    usage
                fi
                cache_dir="$2"
                shift 2
                ;;
            --cache-clear)
                cache_clear=1
                shift
                ;;
            --cache-clear-all)
                cache_clear_all=1
                shift
                ;;
            --cache-info)
                cache_info=1
                shift
                ;;
            -h|--help)
                usage
                ;;
            --)
                shift
                break
                ;;
            -* )
                echo "unknown option: $1" >&2
                exit 1
                ;;
            *)
                if [ -n "$pdf" ]; then
                    echo "unexpected argument: $1" >&2
                    exit 1
                fi
                pdf="$1"
                shift
                ;;
        esac
    done

    if [ "$cache_clear_all" -eq 1 ]; then
        if [ -d "$cache_dir" ]; then
            ${coreutils}/bin/rm -rf "$cache_dir"
        fi
        if [ "$cache_info" -eq 1 ]; then
            echo "cache cleared: $cache_dir" >&2
        fi
        exit 0
    fi

    if [ -z "$pdf" ]; then
        usage
    fi

    if [ ! -f "$pdf" ]; then
        echo "$pdf does not exist" >&2
        exit 1
    fi

    cache_file=""
    if [ "$cache_enabled" -eq 1 ] || [ "$cache_clear" -eq 1 ]; then
        cache_key="$({ ${coreutils}/bin/printf 'pdftc-cache-v%s:' "$cache_version"; ${coreutils}/bin/head -c 65536 "$pdf"; } | ${coreutils}/bin/sha256sum | ${coreutils}/bin/cut -d' ' -f1)"
        cache_file="$cache_dir/$cache_key.txt"
        if [ "$cache_clear" -eq 1 ]; then
            ${coreutils}/bin/rm -f "$cache_file"
        fi
        if [ "$cache_enabled" -eq 1 ] && [ -f "$cache_file" ]; then
            if [ "$cache_info" -eq 1 ]; then
                echo "cache hit: $cache_file" >&2
            fi
            ${coreutils}/bin/cat "$cache_file"
            exit 0
        fi
        if [ "$cache_info" -eq 1 ]; then
            echo "cache miss: $cache_file" >&2
        fi
    elif [ "$cache_info" -eq 1 ]; then
        echo "cache disabled" >&2
    fi

    if [ "$cache_enabled" -eq 1 ]; then
        ${coreutils}/bin/mkdir -p "$cache_dir"
    fi

    if [ "$cache_enabled" -eq 1 ]; then
        ${pdftk}/bin/pdftk "$pdf" dump_data_utf8 | \
        ${ripgrep}/bin/rg --no-config --smart-case --text bookmark'(title|level)'  | \
        ${gnused}/bin/sed '$!N;s/^\([^\n]*\)\n\([^\n]*\)$/\2 \1/' | \
        ${gnused}/bin/sed -r -e 's/BookmarkLevel: //'            \
        -e 's/BookmarkTitle: //'                                 \
        -e 's/^7 /\t\t\t\t\t\t\t/'                               \
        -e 's/^6 /\t\t\t\t\t\t/'                                 \
        -e 's/^5 /\t\t\t\t\t/'                                   \
        -e 's/^4 /\t\t\t\t/'                                     \
        -e 's/^3 /\t\t\t/'                                       \
        -e 's/^2 /\t\t/'                                         \
        -e 's/^1 /\t/'                                           \
        -e 's/^\s+([0-9]+\.){7}[0-9]+\s/\t\t\t\t\t\t\t\t/'       \
        -e 's/^\s+([0-9]+\.){6}[0-9]+\s/\t\t\t\t\t\t\t/'         \
        -e 's/^\s+([0-9]+\.){5}[0-9]+\s/\t\t\t\t\t\t/'           \
        -e 's/^\s+([0-9]+\.){4}[0-9]+\s/\t\t\t\t\t/'             \
        -e 's/^\s+([0-9]+\.){3}[0-9]+\s/\t\t\t\t/'               \
        -e 's/^\s+([0-9]+\.){2}[0-9]+\s/\t\t\t/'                 \
        -e 's/^\s+([0-9]+\.){1}[0-9]+\s/\t\t/'                   \
        -e 's/\t/    /g'                                        | \
        ${coreutils}/bin/tr '[:upper:]' '[:lower:]'            | \
        ${coreutils}/bin/tee "$cache_file"
    else
        ${pdftk}/bin/pdftk "$pdf" dump_data_utf8 | \
        ${ripgrep}/bin/rg --no-config --smart-case --text bookmark'(title|level)'  | \
        ${gnused}/bin/sed '$!N;s/^\([^\n]*\)\n\([^\n]*\)$/\2 \1/' | \
        ${gnused}/bin/sed -r -e 's/BookmarkLevel: //'            \
        -e 's/BookmarkTitle: //'                                 \
        -e 's/^7 /\t\t\t\t\t\t\t/'                               \
        -e 's/^6 /\t\t\t\t\t\t/'                                 \
        -e 's/^5 /\t\t\t\t\t/'                                   \
        -e 's/^4 /\t\t\t\t/'                                     \
        -e 's/^3 /\t\t\t/'                                       \
        -e 's/^2 /\t\t/'                                         \
        -e 's/^1 /\t/'                                           \
        -e 's/^\s+([0-9]+\.){7}[0-9]+\s/\t\t\t\t\t\t\t\t/'       \
        -e 's/^\s+([0-9]+\.){6}[0-9]+\s/\t\t\t\t\t\t\t/'         \
        -e 's/^\s+([0-9]+\.){5}[0-9]+\s/\t\t\t\t\t\t/'           \
        -e 's/^\s+([0-9]+\.){4}[0-9]+\s/\t\t\t\t\t/'             \
        -e 's/^\s+([0-9]+\.){3}[0-9]+\s/\t\t\t\t/'               \
        -e 's/^\s+([0-9]+\.){2}[0-9]+\s/\t\t\t/'                 \
        -e 's/^\s+([0-9]+\.){1}[0-9]+\s/\t\t/'                   \
        -e 's/\t/    /g'                                        | \
        ${coreutils}/bin/tr '[:upper:]' '[:lower:]'
    fi
  '';
}
