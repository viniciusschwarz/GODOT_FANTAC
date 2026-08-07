import sys
import re

with open("scripts/autoloads/scene_manager.gd", "r") as f:
    content = f.read()

# Replace deployment mapping to point to battlefield
content = re.sub(
    r'"deployment":\s*"res://scenes/ui/screens/deployment_screen.tscn",',
    '"deployment": "res://scenes/map/battlefield.tscn",',
    content
)

# Remove battle mapping
content = re.sub(
    r'\s*"battle":\s*"res://scenes/ui/screens/battle_screen.tscn",\n',
    '\n',
    content
)

with open("scripts/autoloads/scene_manager.gd", "w") as f:
    f.write(content)

print("Updated SCENE_MAP")
