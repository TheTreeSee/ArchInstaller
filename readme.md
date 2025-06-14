# ArchInstaller

This Script is a simple way to automate the installation process of the Arch ISO. This script saves time and reduces the chance of human error, making it an ideal tool for both novice and experienced Linux users.

## Usage

This script is designed to be loaded on the machine where the Arch ISO is running.

If qwerty is not your preferred layout, change it.

```bash
loadkeys colemak
```

Curl the script and immediately execute:

```bash
curl -s https://raw.githubusercontent.com/thetreesee/archinstaller/main/install.sh | bash
```

Just curl:

```bash
curl -o install.sh -s https://raw.githubusercontent.com/thetreesee/archinstaller/main/install.sh
```

## Configuration

Edit `config/settings.conf` to customize the installation parameters.

## Structure

- `install.sh`: Main entry point
- `config/`: Configuration files
- `lib/`: Core functionality modules
- `assets/`: Other files we use

## Troubleshooting

If you get the`curl failed to verify the legitimacy` error
please make sure your hardware clock int wrong.

```bash
hwclock
```

if it shows the wrong time please try setting it

```bash
hwclock --set --date="month/day/year hour:minute:second"
hwclock --hctosys
```

now when you try again it should work.
