import os
import sys

def main():
    has_errors = False

    directories_to_check = ['core', 'domain']

    banned_keywords = [
        "get_node(", "get_tree(", "get_parent(", "Owner",
        "$\"", "Input.is_action_", "position", "global_position",
        "load(", "preload("
    ]

    banned_suffixes = [
        "Manager", "Handler", "Processor", "Controller", "Helper", "Util"
    ]

    allowed_suffixes = [
        "Registry", "Driver", "Evaluator", "Buffer", "Resolver", "Sequencer", "Dispatcher"
    ]

    kernel_exceptions = [
        "SimClock", "CommandBus", "EventBus", "SaveRegistry", "EnvelopeValidator", "CoreEnums"
    ]

    for dir_path in directories_to_check:
        if not os.path.exists(dir_path):
            continue

        for root, dirs, files in os.walk(dir_path):
            for file in files:
                if not file.endswith('.gd'):
                    continue

                full_path = os.path.join(root, file)
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Skip legacy/test files if they existed previously
                if file.startswith("test_") and file != "test_layer1_integration.gd":
                    continue

                # Check for SceneTree classes inheritance
                if "extends Node" in content or "extends Control" in content or "extends CanvasItem" in content:
                    # test_layer1_integration.gd is an exception since it extends SceneTree
                    if file != "test_layer1_integration.gd" and file != "test_integration.gd":
                        print(f"[FAIL] {full_path} extends SceneTree class")
                        has_errors = True

                # Check for banned keywords
                for keyword in banned_keywords:
                    if keyword in content:
                        print(f"[FAIL] {full_path} contains banned keyword: {keyword}")
                        has_errors = True

                # Check for class name suffix
                class_name_line = [line for line in content.split('\n') if line.startswith('class_name ')]
                if class_name_line:
                    class_name = class_name_line[0].split('class_name ')[1].strip()

                    if class_name not in kernel_exceptions:
                        has_valid_suffix = False
                        for suffix in allowed_suffixes:
                            if class_name.endswith(suffix):
                                has_valid_suffix = True
                                break

                        if not has_valid_suffix:
                            print(f"[FAIL] {full_path} has class name {class_name} which does not end with an allowed suffix")
                            has_errors = True

                        for banned_suffix in banned_suffixes:
                            if class_name.endswith(banned_suffix):
                                print(f"[FAIL] {full_path} has class name {class_name} which ends with a banned suffix")
                                has_errors = True

    if has_errors:
        sys.exit(1)
    else:
        print("[PASS] All boundary checks passed.")
        sys.exit(0)

if __name__ == "__main__":
    main()
