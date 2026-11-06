# resumeworks

Repository for managing my resume

Run `build-resume` to build all the resume versions.

## Install

To install:

```Nix
{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        resumeworks.url = "github:givikuna/resumeworks";
    };

    outputs = { self, nixpkgs, resumeworks, ... }@inputs: {
        nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            specialArgs = { inherit inputs; };

            modules = [
                ./configuration.nix
            ];
        };
    };
}
```

And in any file do:

```Nix
{ pkgs, inputs, ... }: {
    environment.systemPackages = [
        inputs.resumeworks.packages.${pkgs.system}.default
    ];
}
```

And now it's in your system.

## Interact

```BASH
resumeworks --help
resumeworks -h
```

For the help information

```BASH
resumeworks --list
```

Lists all the resume versions

```Nushell
resumeworks --pdf <version>
```

Places the .pdf here

```Nushell
resumeworks --tex <version>
```

Places the .tex here
