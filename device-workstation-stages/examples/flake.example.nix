# ПРИМЕР. flake.nix в репозитории проекта: окружение разработчика (вариант A)
# и одноразовая VM на NixOS для Proxmox VE из того же flake.
{
  description = "Пример окружения проекта mess.systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Окружение проекта: direnv поднимает его по `use flake` в .envrc
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ git jdk21 gradle nodejs_22 ];
        # Языковые зависимости идут через NORA: адреса задают конфиги клиентов
        # по типовой архитектуре кешей зависимостей, а не этот файл.
      };

      # Одноразовая VM: nixos-rebuild build-image --image-variant proxmox --flake .#sandbox
      nixosConfigurations.sandbox = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ ... }: {
            networking.hostName = "dc1-corp-device-nixos-dev-01";   # пример имени
            users.users.dev = { isNormalUser = true; extraGroups = [ "wheel" ]; };
            services.openssh.enable = true;
            # Секретов станции в VM нет; VM удаляется после работы.
            system.stateVersion = "26.05";
          })
        ];
      };
    };
}
