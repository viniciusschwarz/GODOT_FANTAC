import sys

def main():
    with open('scripts/sim/simulation_server.gd', 'r') as f:
        content = f.read()

    search = """						# Fire projectile
						var unit_3d_pos = Vector3(unit.template_parameters.get("last_coord_x", 0) + 0.5, unit.template_parameters.get("last_coord_y", 0) + 0.5, unit.template_parameters.get("last_coord_z", 0) * 3.0 + 1.0)
						var target = intent.target_coord
						var target_3d_pos = Vector3(target.x + 0.5, target.y + 0.5, target.z * 3.0 + 1.0)
						var direction: Vector3 = (target_3d_pos - unit_3d_pos).normalized()
						var speed = 0.5 # assumed projectile speed"""

    replace = """						# Fire projectile
						var unit_3d_pos = Vector3(unit.template_parameters.get("last_coord_x", 0) + 0.5, unit.template_parameters.get("last_coord_y", 0) + 0.5, unit.template_parameters.get("last_coord_z", 0) * 3.0 + 1.0)
						var target_3d_pos = Vector3.ZERO
						if intent.has("target_id") and working_units.has(intent.target_id):
							var target_unit = working_units[intent.target_id]
							var tx = target_unit.template_parameters.get("last_coord_x", intent.target_coord.x)
							var ty = target_unit.template_parameters.get("last_coord_y", intent.target_coord.y)
							var tz = target_unit.template_parameters.get("last_coord_z", intent.target_coord.z)
							target_3d_pos = Vector3(tx + 0.5, ty + 0.5, tz * 3.0 + 1.0)
						else:
							var target = intent.target_coord
							target_3d_pos = Vector3(target.x + 0.5, target.y + 0.5, target.z * 3.0 + 1.0)

						var direction: Vector3 = (target_3d_pos - unit_3d_pos).normalized()
						var speed = 0.5 # assumed projectile speed"""

    if search in content:
        content = content.replace(search, replace)
        with open('scripts/sim/simulation_server.gd', 'w') as f:
            f.write(content)
        print("Patched SimulationServer.")
    else:
        print("Could not find search block in SimulationServer.")

if __name__ == "__main__":
    main()
