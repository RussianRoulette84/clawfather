#!/bin/bash

# --- ywizz Banner (Visual Headers & ASCII) ---

# Centering helper for ASCII art
center_ascii() {
    local text="$1"
    local width="${2:-101}"
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 100)
    local pad=$(( (term_width - width) / 2 ))
    if [ $pad -gt 0 ]; then
        for ((i=0; i<pad; i++)); do printf " "; done
    fi
    printf "%b\n" "$text"
}

show_banner() {
    local W=101
    center_ascii "${C1}   /\$\$\$\$\$\$  /\$\$        /\$\$\$\$\$\$  /\$\$      /\$\$ /\$\$\$\$\$\$\$\$ /\$\$\$\$\$\$  /\$\$\$\$\$\$\$\$ /\$\$   /\$\$ /\$\$\$\$\$\$\$\$ /\$\$\$\$\$\$\$ ${NC}" $W
    center_ascii "${C2}  /\$\$__  \$\$| \$\$       /\$\$__  \$\$| \$\$  /\$ | \$\$| \$\$_____//\$\$__  \$\$|__  \$\$__/| \$\$  | \$\$| \$\$_____/| \$\$__  \$\$${NC}" $W
    center_ascii "${C3} | \$\$  \__/| \$\$      | \$\$  \ \$\$| \$\$ /\$\$\$| \$\$| \$\$     | \$\$  \ \$\$   | \$\$   | \$\$  | \$\$| \$\$      | \$\$  \ \$\$${NC}" $W
    center_ascii "${C4} | \$\$      | \$\$      | \$\$\$\$\$\$\$\$| \$\$ \$\$/\$\$ \$\$| \$\$\$\$\$  | \$\$\$\$\$\$\$\$   | \$\$   | \$\$\$\$\$\$\$\$| \$\$\$\$\$   | \$\$\$\$\$\$\$/${NC}" $W
    center_ascii "${C5} | \$\$      | \$\$      | \$\$__  \$\$| \$\$\$\$_  \$\$\$\$| \$\$__/  | \$\$__  \$\$   | \$\$   | \$\$__  \$\$| \$\$__/   | \$\$__  \$\$${NC}" $W
    center_ascii "${C6} | \$\$    \$\$| \$\$      | \$\$  | \$\$| \$\$\$/ \\  \$\$\$| \$\$     | \$\$  | \$\$   | \$\$   | \$\$  | \$\$| \$\$      | \$\$  \ \$\$${NC}" $W
    center_ascii "${C7} |  \$\$\$\$\$\$/| \$\$\$\$\$\$\$\$| \$\$  | \$\$| \$\$/   \\  \$\$| \$\$     | \$\$  | \$\$   | \$\$   | \$\$  | \$\$| \$\$\$\$\$\$\$\$| \$\$  | \$\$${NC}" $W
    center_ascii "${C8}  \______/ |________/|__/  |__/|__/     \__/|__/     |__/  |__/   |__/   |__/  |__/|________/|__/  |__/                       ${accent_color}${CLAWFATHER_VERSION:-v1.1} by: Jaroslav84${RESET}" 20
    printf "\n"
}

show_lobster() {
    printf "\n"
    local W=10
    center_ascii "${C1}⠀   ⠀⠀⢀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C1}⠀⠀⢀⣠⣤⣼⣿⣿⣿⣾⣶⡤⠄⠀⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C2}⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⡀⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C2}⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣉⡄⠀⠀⠀⠀${NC}" $W
    center_ascii "${C3}⢀⣾⢿⣿⣿⡿⠿⠿⠿⠿⢿⣿⣿⡿⣿⢇⠀⠀⠀⠀${NC}" $W
    center_ascii "${C3}⠀⠀⠀⠀⢨⣷⡀⠀⠀⠐⣢⣬⣿⣷⡁⣾⠀⠀⠀⠀${NC}" $W
    center_ascii "${C4}⢀⡠⣤⣴⣾⣿⣿⣷⣦⣿⣿⣿⣿⣿⠿⡇⠀⠀⠀⠀${NC}" $W
    center_ascii "${C4}⠈⠙⣿⡿⠚⠿⠟⢿⣟⣿⣿⣿⣿⣿⠉⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C5}⠀⠀⣹⠵⠀⠠⠼⠯⠝⣻⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C5}⠀⠀⠻⢂⡄⠒⠒⠛⣿⡿⠛⠻⠋⣼⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C6}⠀⠀⠠⡀⠰⠶⠿⠿⠷⠞⠀⣠⣴⠟⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C6}⠀⠀⠀⠈⠂⣀⠀⠀⠀⠀⢠⠟⠉⠀⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C7}⠀⠀⠀⠀⠀⠘⠓⠂⠀⠐⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C7}⠀⠀⠀⠀⠀⠀⠀⠐⡒⣂⣤⣤⠀⠀⠀⠀⠀⠀⠀⠀${NC}" $W
    center_ascii "${C8}⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⢀⠤⠄⡀${NC}" $W
    center_ascii "${C8}⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⢀⡜⠠⢂⡗${NC}" $W
    center_ascii "${C9}⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⠀⢓⠢⢬⡟${NC}" $W
    center_ascii "${C9}⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⢸⠍⠀  ${NC}" $W
    printf "\n"
}

show_head() {
    printf "\n"
    printf "   %b\n" "${C1}⠀   ⠀⠀⢀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C1}⠀⠀⢀⣠⣤⣼⣿⣿⣿⣾⣶⡤⠄⠀⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C2}⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⡀⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C2}⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣉⡄⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C3}⢀⣾⢿⣿⣿⡿⠿⠿⠿⠿⢿⣿⣿⡿⣿⢇⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C3}⠀⠀⠀⠀⢨⣷⡀⠀⠀⠐⣢⣬⣿⣷⡁⣾⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C4}⢀⡠⣤⣴⣾⣿⣿⣷⣦⣿⣿⣿⣿⣿⠿⡇⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C4}⠈⠙⣿⡿⠚⠿⠟⢿⣟⣿⣿⣿⣿⣿⠉⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C5}⠀⠀⣹⠵⠀⠠⠼⠯⠝⣻⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C5}⠀⠀⠻⢂⡄⠒⠒⠛⣿⡿⠛⠻⠋⣼⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C6}⠀⠀⠠⡀⠰⠶⠿⠿⠷⠞⠀⣠⣴⠟⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C6}⠀⠀⠀⠈⠂⣀⠀⠀⠀⠀⢠⠟⠉⠀⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C7}⠀⠀⠀⠀⠀⠘⠓⠂⠀⠐⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀${NC}"
    printf "\n"
}

# Head (left) + dollar banner (right) side by side
# When YWIZZ_ASCII_PRIMARY is set (from install config), use it; else fallback to hardcoded.
show_banner_combined() {
    if [ ${#YWIZZ_ASCII_PRIMARY[@]} -gt 0 ] && command -v draw_banner_frame &>/dev/null && command -v generate_banner_palette &>/dev/null; then
        generate_banner_palette
        local text_colors=("${GENERATED_TEXT_COLORS[@]}")
        local num_rows=${#YWIZZ_ASCII_PRIMARY[@]}
        local lobster_colors=() text_frame_colors=()
        # Use same color spectrum for both skull (lobster) and CLAWFATHER (text) so they match.
        for ((r=0; r<num_rows; r++)); do
            local c="${text_colors[$r]:-$C1}"
            lobster_colors+=("$c")
            text_frame_colors+=("$c")
        done
        printf "\n"
        draw_banner_frame "${lobster_colors[@]}" "${text_frame_colors[@]}" "${YWIZZ_ASCII_PRIMARY[@]}"
        return
    fi
    local gap=" "
    printf "\n"
    printf "   %b\n" "${C1}⠀   ⠀⠀⢀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C1}⠀⠀⢀⣠⣤⣼⣿⣿⣿⣾⣶⡤⠄⠀⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C2}⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⡀⠀⠀⠀⠀⠀⠀${NC}"
    printf "%b%s%b%b%s%b\n" "${C2}   ⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣉⡄⠀⠀⠀⠀${NC}" "$gap" "" "${C1}   /\$\$\$\$\$\$  /\$\$        /\$\$\$\$\$   /\$\$       /\$\$ /\$\$\$\$\$\$\$ /\$\$\$\$\$\$  /\$\$\$\$\$\$\$\$ /\$\$   /\$\$  /\$\$\$\$\$\$\$ /\$\$\$\$\$\$ ${NC}" "" ""
    printf "%b%s%b%b%s%b\n" "${C3}   ⢀⣾⢿⣿⣿⡿⠿⠿⠿⠿⢿⣿⣿⡿⣿⢇⠀⠀⠀⠀${NC}" "$gap" "" "${C2}  /\$\$__  \$\$| \$\$       /\$\$__  \$\$| \$\$  /\$ | \$\$| \$\$_____//\$\$__  \$\$|__  \$\$__/| \$\$  | \$\$| \$\$_____/| \$\$__  \$\$${NC}" "" ""
    printf "%b%s%b%b%s%b\n" "${C3}   ⠀⠀⠀⠀⢨⣷⡀⠀⠀⠐⣢⣬⣿⣷⡁⣾⠀⠀⠀⠀${NC}" "$gap" "" "${C3} | \$\$  \__/| \$\$      | \$\$  \ \$\$| \$\$ /\$\$\$| \$\$| \$\$     | \$\$  \ \$\$   | \$\$   | \$\$  | \$\$| \$\$      | \$\$  \ \$\$${NC}" "" ""
    printf "%b%s%b%b%s%b\n" "${C4}   ⢀⡠⣤⣴⣾⣿⣿⣷⣦⣿⣿⣿⣿⣿⠿⡇⠀⠀⠀⠀${NC}" "$gap" "" "${C4} | \$\$      | \$\$      | \$\$\$\$\$\$\$\$| \$\$ \$\$/\$\$ \$\$| \$\$\$\$\$  | \$\$\$\$\$\$\$\$   | \$\$   | \$\$\$\$\$\$\$\$| \$\$\$\$\$   | \$\$\$\$\$\$/${NC}" "" ""
    printf "%b%s%b%b%s%b\n" "${C4}   ⠈⠙⣿⡿⠚⠿⠟⢿⣟⣿⣿⣿⣿⣿⠉⠀⠀⠀⠀⠀${NC}" "$gap" "" "${C5} | \$\$      | \$\$      | \$\$__  \$\$| \$\$\$\$_  \$\$\$\$| \$\$__/  | \$\$__  \$\$   | \$\$   | \$\$__  \$\$| \$\$__/   | \$\$__  \$\$${NC}" "" ""
    printf "%b%s%b%b%s%b\n" "${C5}   ⠀⠀⣹⠵⠀⠠⠼⠯⠝⣻⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀${NC}" "$gap" "" "${C6} | \$\$    \$\$| \$\$      | \$\$  | \$\$| \$\$\$/ \\  \$\$\$| \$\$     | \$\$  | \$\$   | \$\$   | \$\$  | \$\$| \$\$      | \$\$  \ \$\$${NC}" "" ""
    printf "%b%s%b%b%s%b\n" "${C5}   ⠀⠀⠻⢂⡄⠒⠒⠛⣿⡿⠛⠻⠋⣼⠀⠀⠀⠀⠀⠀${NC}" "$gap" "" "${C7} |  \$\$\$\$\$\$/| \$\$\$\$\$\$\$\$| \$\$  | \$\$| \$\$/   \\  \$\$| \$\$     | \$\$  | \$\$   | \$\$   | \$\$  | \$\$| \$\$\$\$\$\$\$\$| \$\$  | \$\$${NC}" "" ""
    printf "%b%s%b%b%s%b\n" "${C6}   ⠀⠀⠠⡀⠰⠶⠿⠿⠷⠞⠀⣠⣴⠟⠀⠀⠀⠀⠀⠀${NC}" "$gap" "" "${C8}  \______/ |________/|__/  |__/|__/     \__/|__/     |__/  |__/   |__/   |__/  |__/|________/|__/  |__/${NC}" "" ""
    printf "   %b\n" "${C6}⠀⠀⠀⠈⠂⣀⠀⠀⠀⠀⢠⠟⠉⠀⠀⠀⠀⠀⠀⠀${NC}"
    printf "   %b\n" "${C7}⠀⠀⠀⠀⠀⠘⠓⠂⠀⠐⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀                       ${accent_color}${CLAWFATHER_VERSION:-v1.1} by: Yaro${RESET}"
}

show_colors() {
    printf "   %b[ TUI Color Palette ]%b\n" "$CYAN" "$RESET"
    printf "   %bC1: ######%b  %bC2: ######%b  %bC3: ######%b\n" "$C1" "$RESET" "$C2" "$RESET" "$C3" "$RESET"
    printf "   %bC4: ######%b  %bC5: ######%b  %bC6: ######%b\n" "$C4" "$RESET" "$C5" "$RESET" "$C6" "$RESET"
    printf "   %bC7: ######%b  %bC8: ######%b  %bC9: ######%b\n" "$C7" "$RESET" "$C8" "$RESET" "$C9" "$RESET"
    printf "   %bdim:  ####%b (Dim Component)\n\n" "$dim_color" "$RESET"
}
