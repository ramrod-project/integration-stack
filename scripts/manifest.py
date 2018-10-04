from importlib.util import spec_from_file_location, module_from_spec
from json import dump, load
from os import listdir, mkdir, path, remove, rename
from shutil import copyfile
from sys import argv, stderr

INIT_PLUGINS = "__init__.py"
EXTRA_DIR = "./extra_plugins"
MANIFEST_FILE = "./manifest.json"
OS_MAP = {
    "1": "nt",
    "2": "posix",
    "3": "all"
}

def get_plugins(directory):
    plugin_names = []
    for f in listdir(directory):
        if f.startswith('__') or not f.endswith('.py'):
            continue
        print("".join(("Found plugin: ", f)))
        plugin_names.append(f)
    return plugin_names


def get_other_files(plugins, directory):
    other_files = []
    for f in listdir(directory):
        if f == INIT_PLUGINS:
            continue
        if f not in plugins:
            other_files.append(f)
    return other_files


def move_extra_files(plugin, directory, other_files):
    if not path.isdir(EXTRA_DIR):
        mkdir(EXTRA_DIR)
        copyfile("/".join((directory, INIT_PLUGINS)), "/".join((EXTRA_DIR, INIT_PLUGINS)))
    # Move plugin and copy init file
    rename("/".join((directory, plugin)), "/".join((EXTRA_DIR, plugin)))
    i = 0
    while i < len(other_files):
        while True:
            print("Does the plugin {} require the file/directory '{}'?\n".format(plugin, other_files[i]))
            print("\t1) Yes\n\t2) No\n")
            extra_choice = input("Selection:")
            if extra_choice not in ["1", "2"]:
                print("Please enter 1 or 2\n")
                continue
            break
        if extra_choice == "2":
            i += 1
            continue
        rename("/".join((directory, other_files[i])), "/".join((EXTRA_DIR, other_files[i])))
        del other_files[i]
    return other_files
        

def main():
    if len(argv) != 2:
        stderr.write("Usage: python3 manifest.py <plugin_directory>\n")
        exit(1)
    if not path.isdir(argv[1]):
        stderr.write("Plugins directory not provided or not found!\n")
        exit(2)
    
    plugins_dir = argv[1]
    
    plugins = get_plugins(plugins_dir)
    if len(plugins) < 1:
        print("no plugins found in {}".format(plugins_dir))
        exit(1)

    other_files = get_other_files(plugins, plugins_dir)
    manifest = []

    if path.isfile(MANIFEST_FILE):
        remove(MANIFEST_FILE)

    for plugin in plugins:
        while True:
            print("Which operating system does plugin {} support?\n".format(plugin[:-3].strip(".")))
            print("\t1) Windows\n\t2) Linux\n\t3) All\n")
            os_choice = input("Selection:")
            if os_choice not in ["1", "2", "3"]:
                print("Please enter 1,2, or 3\n")
                continue
            break
        extra = False
        if os_choice in ["2", "3"]:
            while True:
                print("Does the plugin {} require extra features (Wine/zugbruecke - call Windows DLLs, M2Crypto - DES, RSA, etc.)?\n".format(plugin[:-3].strip(".")))
                print("\t1) Yes\n\t2) No\n")
                extra_sel = input("Selection:")
                if extra_sel not in ["1", "2"]:
                    print("Please enter 1 or 2\n")
                    continue
                if extra_sel == "1":
                    other_files = move_extra_files(plugin, plugins_dir, other_files)
                    extra = True
                break
        manifest.append({
            "Name": plugin[:-3].strip("."),
            "OS": OS_MAP[os_choice],
            "Extra": extra
        })
    with open(MANIFEST_FILE, "w") as outfile:
        print("Writing manifest: {} to file: {}".format(
            manifest,
            MANIFEST_FILE
        ))
        dump(manifest, outfile)
    print("Done!")


if __name__ == '__main__':
    main()