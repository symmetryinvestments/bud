Dub stores a version field in the dub.json/sdl when it fetches the package.
The zip it gets is probably taken directly from github, but
`PackageManager.storeFetchedPackage` overwrites it to put a version
field there. Instead of using the package path to figure out the version
number (e.g. ~/.dub/packages/foo-1.2.3/foo would have version 1.2.3), it
tries to get the version from the package recipe. If that fails, it uses
git to find out the version.

`PackageManager.storeFetchedPackage` is called from `dub.fetch`.
It first gets all the metadata associated with the package by calling
`PackageSupplier.fetchPackageRecipe`. The runtime type of
`PackageSupplier` is usually `RegistryPackageSupplier`. The
member function name is a misnomer - it doesn't actually fetch the package
recipe, it fetches metadata then picks the best version from that.
As example of the API call it makes to the registry is this URL:

    https://code.dlang.org/api/packages/infos?packages=%5B%22cerealed%22%5D&include_dependencies=true&minimize=true

`dub.fetch` first tries to get the required package from the package
manager. If it's not cached (i.e. already on the filesystem) it then
delegates to the package supplier to download a zip file then
asks the package manager to store the fetched package (the zip file)
in the specified location (usually ~/.dub/packages/<pkg>-<version>/pkg).
This is when it overwrites the recipe to add the version number.
