## Active noise RADAR with frequency sweep

### Experimental setup

The initial setup was running on a Dell Precision M6500 laptop with an Analog
Devices Inc. PlutoSDR connected to the USB2 port and an Ettus Research B210
connected to the USB3 port. The random phase modulation on the carrier transmitted 
by the PlutoSDR (TX port) is collected with one B210 port (B - RX2) while the
other port (A - RX2) is connected to the receiving antenna. The PlutoSDR is connected
to a 10-dB coupler (Mini Circuits ZEDC-10-2B) whose direct output is connected to the
transmitting antenna and coupled output is connected through a 20 dB attenuator
to the B210 input.

Because installing the software on the laptop is hardly reproducible (GNU Radio 3.8,
libiio + libad9361 + gr-iio supporting the PlutoSDR as described at
https://wiki.analog.com/resources/tools-software/linux-software/gnuradio + need
to modifiy gr-iio to increase sweep rate) and since the newer (April 2020) Raspberry Pi 4 (RPi4)
is fitted with two USB 3 ports, the whole setup was ported to this platform.

In order to setup the system, Buildroot is downloaded at https://github.com/buildroot/buildroot
since it supports the full 64-bit ARM processor of the RPi4. Additional packages needed are
provided through a BR2_EXTERNAL mechanism using the additional files found in the ``for_next``
branch of https://github.com/oscimp/PlutoSDR (i.e. at
https://github.com/oscimp/PlutoSDR/tree/for_next). After git cloning the latter repository, 
in a shell ``source sourceme.ggm`` will load the BR2_EXTERNAL additional packages. Then go to 
the buildroot directory, copy the provided raspberrypi4_64_defconfig into the Buildroot configs
directory, and ``make raspberrypi4_64_defconfig`` followed by ``make``. After a very long 
compilation, the ``output/images/sdcard.img`` is written (``dd``) to a micro-SD card for
running on the RPi4.

<img src=pictures/DSC00624smallr.jpg>  <img src=pictures/DSC00625small.jpg>


### RPi4 configuration:

Connect with a USB-TTL converter and set the IP address of the RPi4 to 192.168.0.165:
```shell
ifconfig eth0 192.168.0.165
```

The root password is root (needed for ssh to the board)

It is believed that at least the PlutoSDR must be powered from an external power
supply (ie not from the USB cable going to the RPi4). It might be safe as well to
power the B210 from an external supply, although it does not seem to be mandatory as
the RPi4 seems to source enough current on its USB3 port.

Once the SD-card is written with ``sdcard.img``, run it from the RPi4, and connect
to the RPi4 after configuring the host computer Ethernet interface with a 192.168.0.X
IP address (X != 165). The B210 firmware files must be copied from the host computer
to the RPi4 (somehow ``uhd_images_downloader`` seems to be failing on the RPi4):
on the RPi4, 
```shell
mkdir -p /usr/share/uhd/images/
``` 
and then 
```shell
scp 192.168.0.X:/usr/share/uhd/images/*b2* /usr/share/uhd/images
```

It is also possible to copy the files from the host computer to the 
``output/target/usr/share/uhd/images`` directory of buildroot, then ``make`` to
generate again ``sdcard.img`` to be ``dd`` to the SD-card.

### Signal acqusisition

Copy from the host computer ``zeromq_demo_rev1.py`` to the ``root`` directory
of the RPi4 (``scp zeromq_demo_rev1.py 192.168.0.165:/root``), connect to the
RPi 4 with ``ssh 192.168.0.165`` and from its shell, launch ``python3 zeromq_demo_rev1.py``.
This will start the GNU Radio flowchart and run a ZeroMQ Publish server as well as a TCP
server.

From the host computer, run ``octave`` and launch ``zeromq_demo_rev1`` (running hence
the ``zeromq_demo_rev1.m`` script): the TCP server on the RPi4 must achnoledge the connection
and data will start streaming from th RPi4 to the host computer. After the whole
frequency sweep, spectra are concatenated and the high resolution correlation is displayed,
hopefully with some echoes in the positive delay domain.

### Signal processing

The ``700_750_house_final4_with_protection.mat.gz`` dataset was collected with 
``zeromq_demo_rev1.py`` controlling the B210 and the PlutoSDR, while the frequency sweep 
and data collection is controlled by ``zeromq_demo_rev1.m``.

The dataset can be postprocessed using ``go.m`` running with GNU/Octave or Matlab.

A movie of the system running is found at http://jmfriedt.free.fr/active_radar_RPi4.mp4
