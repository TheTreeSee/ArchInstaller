# ArchInstaller

This Script is a simple way to automate the installation process of the Arch ISO. This script saves time and reduces the chance of human error, making it an ideal tool for both novice and experienced Linux users.

## Usage

This script is designed to be loaded on the machine where the Arch ISO is running.

If qwerty is not your preferred layout, change it.

```bash
loadkeys colemak
```
Curl the script:

```bash
curl -o installer.sh https://raw.githubusercontent.com/thetreesee/archinstaller/main/installer.sh
```

Change the settings if needed

```bash
vim installer.sh
```

Change its execution policies:

```bash
chmod +x installer.sh
```

and run it:

```bash
./installer.sh
```
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

## Assets

There are some extra scripts and configs that we use in here, you shouldn't worry about this stuff too much.
