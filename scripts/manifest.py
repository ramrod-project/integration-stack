from importlib.util import spec_from_file_location, module_from_spec
from json import dump, load
from os import listdir, path
from sys import argv, stderr


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
    for plugin in plugins:
        manifest.append({"Name": plugin})
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