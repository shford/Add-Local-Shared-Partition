# Bash Scripts
> A bash script to mount a partition, add a symlink, and add an fstab entry.

This script should be pretty idiot proof so hopefully someone else will also enjoy being able to conveniently access one shared local partiton across different linux OS's.

![](Header.png)

## Installation

OS X & Linux:

```sh
git clone https://github.com/shford/Add-Local-Shared-Partition.git
cd ~/Desktop/
chmod 744 mountScript.sh
sudo ./mountScript.sh
```

## Release History

The script should be working. I still need to add a line to create the fstab entry. Please let me know if there are any issues.

## Meta

Distributed under the MIT license.

## Contributing

1. Fork it (<https://github.com/yourname/yourproject/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
