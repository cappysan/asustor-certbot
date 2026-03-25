# deps.d

Files in `/usr/local/AppCentral/cappysan-*/deps.d/` will always overwrite files that have been moved to `/share/Configuration/*/*`. With the first "*" being the name of the package, and the second "*" being a sub directory other than `deps.d`

Files in `/share/Configuration/*/deps.d/*/` will never overwrite files that have been moved into `/share/Configuration/*/*`.
