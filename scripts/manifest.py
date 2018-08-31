from importlib.util import spec_from_file_location, module_from_spec
from json import dump, load
from os import listdir, path
from sys import argv, stderr

OS_MAP = {
    "1": "nt",
    "2": "posix",
    "3": "all"
}


def get_plugins(directory):
    plugin_names = []
    for file in listdir(directory):
        if file.startswith('__') or not file.endswith('.py'):
            continue
        plugin_name = file[:-3].strip(".")
        print("".join(("Found plugin: ", plugin_name)))
        plugin_names.append(plugin_name)
        """plugin_spec = spec_from_file_location(
            ".".join(("plugins", plugin_name)),
            "".join([
                directory,
                "/",
                plugin_name,
                ".py"
            ])
        )
        plugin = module_from_spec(plugin_spec)
        plugin_spec.loader.exec_module(plugin)
        print("".join(("Loaded plugin: ", plugin_name)))"""
    return plugin_names


def main():
    if len(argv) != 2:
        stderr.write("Usage: python3 manifest.py <plugin_directory>\n")
        exit(1)
    if not path.isdir(argv[1]):
        stderr.write("Plugins directory not provided or not found!\n")
        exit(2)
    
    plugins = get_plugins(argv[1])
    manifest = []

    i = 0
    while i < len(plugins):
        print("Which operating system does plugin {} support?\n".format(plugins[i]))
        print("\t1) Windows\n\t2) Linux\n\t3) All\n")
        os = input("Selection:")
        if os not in ["1", "2", "3"]:
            print("Please enter 1,2, or 3\n")
            continue
        manifest.append({
            "Name": plugins[i],
            "OS": OS_MAP[os]
        })
        i += 1
    destination_filename = "./manifest.json"
    with open(destination_filename, "w") as outfile:
        print("Writing manifest: {} to file: {}".format(
            manifest,
            destination_filename
        ))
        dump(manifest, outfile)
    print("Done!")


if __name__ == '__main__':
    main()