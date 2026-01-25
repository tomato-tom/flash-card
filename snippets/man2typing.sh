#!/bin/bash

# man2typing.sh
# Extract natural, well-formed English sentences from a man page for typing practice.
# Usage: ./man2typing.sh <command_name>

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <command>" >&2
    exit 1
fi

CMD="$1"

# Force English locale to ensure consistent man page content
LANG=C man "$CMD" 2>/dev/null |

# ------------------------------------------------------------------
# Reconstruct paragraphs and fix hyphenated word breaks
# ------------------------------------------------------------------
# Man pages often break long words at line ends like:
#   "in-"
#   " teger"
# We detect lines ending with a lowercase letter + hyphen,
# and merge them with the next line without the hyphen or extra space.
awk '
BEGIN {
    # Buffer to hold partial line during hyphenated word reconstruction
    buffer = ""
}

# Section headers (e.g., "DESCRIPTION", "OPTIONS") or empty lines:
# Flush any pending buffer and skip.
/^[A-Z][A-Z ]*$/ || !NF {
    if (buffer != "") {
        printf "%s ", buffer
        buffer = ""
    }
    next
}

# Only process indented lines (these are body text, not headers)
/^[[:space:]]/ && NF {
    # Remove leading whitespace from the current line
    line = $0
    gsub(/^[ \t]+/, "", line)

    if (buffer != "") {
        # If previous buffer ended with a lowercase letter + hyphen,
        # it means the word was split across lines.
        if (buffer ~ /[a-z]-$/) {
            # Remove the trailing hyphen and concatenate directly
            sub(/-$/, "", buffer)
            buffer = buffer line
        } else {
            # Normal case: add a space between words
            buffer = buffer " " line
        }
    } else {
        # Start new buffer
        buffer = line
    }

    # If the current buffer does NOT end with a hyphenated word,
    # output it immediately to avoid over-buffering.
    if (buffer !~ /[a-z]-$/) {
        printf "%s ", buffer
        buffer = ""
    }
}

# At end of input, flush any remaining buffer
END {
    if (buffer != "") {
        printf "%s ", buffer
    }
    printf "\n"
}' |

# Collapse multiple spaces into one
tr -s ' ' |

# Split on periods followed by space or end-of-line.
# Each sentence should end with a period.
sed 's/\([^.]\+\.\)/\1\n/g' |

# Keep only lines that end with a period
grep '\.$' |

# Trim leading/trailing whitespace
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |

# ------------------------------------------------------------------
# Remove variable/constant names at the beginning of a line
# ------------------------------------------------------------------
# Examples to clean:
#   "BASH Expands to..."          → "Expands to..."
#   "UID The real user ID..."     → "The real user ID..."
#   "BASH_VERSINFO[5] The value..." → "The value..."
#
# Condition:
#   - First word contains NO lowercase letters (i.e., it's a constant/variable)
#   - The rest of the line starts with an uppercase letter (natural sentence)
awk '
{
    first_word = $1
    rest_of_line = $0

    # Remove the first word and any following whitespace
    sub(/^[^[:space:]]+[[:space:]]+/, "", rest_of_line)

    # Check if first word has no lowercase letters:
    #   tolower(first_word) == first_word  → has lowercase or is empty/symbols
    #   tolower(first_word) != first_word  → all uppercase/digits/symbols (no [a-z])
    #
    # Also ensure the remaining line starts with an uppercase letter (natural English)
    if (length(first_word) > 0 && tolower(first_word) != first_word && rest_of_line ~ /^[A-Z]/) {
        print rest_of_line
    } else {
        print $0
    }
}' |

# ------------------------------------------------------------------
# Apply quality filters AFTER variable removal
# ------------------------------------------------------------------
# Some lines may become too short or invalid after step 6, so re-filter:
#   - Must have at least 2 words (avoid fragments like "Enabled.")
#   - Must start with an uppercase letter (natural sentence start)
#   - Must be at least 15 characters long (avoid "Bash-5." etc.)
awk '
NF >= 2 && /^[A-Z]/ && length($0) >= 15
' |

# ------------------------------------------------------------------
# STEP 8: Remove duplicate sentences while preserving order
# ------------------------------------------------------------------
# Use associative array to track seen lines
awk '!seen[$0]++'
