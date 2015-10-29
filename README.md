# evolvable-NES
Neuroevolution experiments for NES games

## Setup
You will need to install fceux for your distribution (e.g. `apt-get install fceux`), then torch (http://torch.ch/docs/getting-started.html).
To use the graphical components (iup) in fceux you'll need to install them manually by following those two guides: [one](https://github.com/henix/blog.henix.info/blob/master/unused/oldblogs/install-iuplua-on-linux.md) and [two](https://raw.githubusercontent.com/asfdfdfd/fceux/master/README-SDL). Then you can install fceux for Windows (has debugger, chaat search and other useful goodies), download the roms and copy the savestates by running `./setup.sh`.

## Resources
1. [SMB RAM map](http://datacrystal.romhacking.net/wiki/Super_Mario_Bros.:RAM_map)
2. [MarI/O - Machine Learning for Video Games (video)](https://youtu.be/qv6UVOQ0F44)
3. [MarI/O (code)](http://pastebin.com/ZZmSNaHX)
4. [CMS-ES implementation in Matlab/Octave](https://www.lri.fr/~hansen/purecmaes.m)
