
#!/bin/bash

# Get the list of players and their status
current_player=$(playerctl -l | grep -E 'spotify|firefox|brave' | while read player; do
    # Strip instance information if it exists
    player_name=$(echo "$player" | sed 's/\..*//')
    
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [[ "$status" == "Playing" ]]; then
        echo "$player_name"
        break
    fi
done)


# Display emoji or Unicode based on the active player
if [[ "$current_player" == "spotify" ]]; then
    icon=""  # Spotify icon
elif [[ "$current_player" == "firefox" || "$current_player" == "brave" ]]; then
    icon="" # YouTube icon
else
    icon=""  # No icon if nothing is playing
fi

# Display song details with icon only if a player is active
if [[ -n "$current_player" ]]; then
    song_info=$(playerctl -p "$current_player" metadata --format '{{title}} - {{artist}}' 2>/dev/null)
    max_length=50
    if [[ ${#song_info} -gt $max_length ]]; then
        song_info="${song_info:0:$max_length}..."
    fi
    echo "$icon $song_info"
else
    echo "... 💤 Cricket 🦗 noises 💤 ..."  # No active player
fi