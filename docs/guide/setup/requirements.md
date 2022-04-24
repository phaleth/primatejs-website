# Requirements

## Running Primate

Primate requires Node.js version 17.2.0 or later.

Primate is developed and tested on Arch Linux. On Arch Linux, you can install
Node.js via

```
pacman -S nodejs
```

Running a Primate app on anything other than Arch Linux will probably work if
you use the required Node.js version.

## Generating certificates

To generate your local SSL key and certificate, you will need OpenSSL or another
tool that generates certificates. On Arch Linux, you can install OpenSSL via

```
pacman -S openssl
```

## Cloning repositories

If you intend to clone the minimal app repository or any other official Primate
repository, you will need git, installable via

```
pacman -S git
```
