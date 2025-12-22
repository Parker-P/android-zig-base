# Android Zig Template
Base from which to start to develop android apps using zig

## How to build
- Install docker desktop, make sure it's in Linux mode
- Run the build.bat batch script if on Windows, otherwise just copy the contents of the batch script and paste into your bash if on Linux
- The resulting apk will be final.apk in the root folder of the project

## Important notes
- The project is specifically built for arm64-v8a ABI devices, if your device doesn't support that ABI it won't work. Help is appreciated to add support for other ABIs
- Android doesn't allow installing unsigned APKs, and for simplicity the Docker image that builds the APK signs it with a locally generated keystore, using pass123 as password. If you want to sign the app with your own signature file, you will need to generate your own java keystore file and use that in the Docker image