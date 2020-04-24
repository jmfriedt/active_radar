#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Not titled yet
# GNU Radio version: 3.8.1.0

from gnuradio import analog
from gnuradio import blocks
import numpy
from gnuradio import filter
from gnuradio import gr
from gnuradio.filter import firdes
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import uhd
import time
from gnuradio import zeromq
import iio
import threading
import socket


class t(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "Not titled yet")

        ##################################################
        # Variables
        ##################################################
        self.samp_rate = samp_rate = int(2.7e6)
        self.f = f = int(650e6)
        self.N = N = 140000

        ##################################################
        # Blocks
        ##################################################
        self.zeromq_pub_sink_0 = zeromq.pub_sink(gr.sizeof_gr_complex, N, 'tcp://127.0.0.1:5555', 100, False, -1)
        self.uhd_usrp_source_0 = uhd.usrp_source(
            ",".join(("", "")),
            uhd.stream_args(
                cpu_format="fc32",
                args='',
                channels=list(range(0,2)),
            ),
        )
        self.uhd_usrp_source_0.set_center_freq(f, 0)
        self.uhd_usrp_source_0.set_gain(70, 0)
        self.uhd_usrp_source_0.set_antenna('RX2', 0)
        self.uhd_usrp_source_0.set_center_freq(f, 1)
        self.uhd_usrp_source_0.set_gain(40, 1)
        self.uhd_usrp_source_0.set_antenna('RX2', 1)
        self.uhd_usrp_source_0.set_samp_rate(samp_rate)
        self.uhd_usrp_source_0.set_time_unknown_pps(uhd.time_spec())
        self.iio_pluto_sink_0 = iio.pluto_sink('', f, samp_rate, 20000000, 32768, False, 30.0, '', True)
        self.dc_blocker_xx_0 = filter.dc_blocker_ff(32, True)
        self.blocks_stream_to_vector_0 = blocks.stream_to_vector(gr.sizeof_gr_complex*1, N)
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_ff(3.1415)
        self.blocks_magphase_to_complex_0 = blocks.magphase_to_complex(1)
        self.blocks_keep_one_in_n_0 = blocks.keep_one_in_n(gr.sizeof_gr_complex*N, 1)
        self.blocks_interleave_0 = blocks.interleave(gr.sizeof_gr_complex*1, 1)
        self.blocks_int_to_float_0 = blocks.int_to_float(1, 1)
        self.analog_random_source_x_0 = blocks.vector_source_i(list(map(int, numpy.random.randint(0, 2, N))), True)
        self.analog_const_source_x_0 = analog.sig_source_f(0, analog.GR_CONST_WAVE, 0, 0, 1)



        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_const_source_x_0, 0), (self.blocks_magphase_to_complex_0, 0))
        self.connect((self.analog_random_source_x_0, 0), (self.blocks_int_to_float_0, 0))
        self.connect((self.blocks_int_to_float_0, 0), (self.dc_blocker_xx_0, 0))
        self.connect((self.blocks_interleave_0, 0), (self.blocks_stream_to_vector_0, 0))
        self.connect((self.blocks_keep_one_in_n_0, 0), (self.zeromq_pub_sink_0, 0))
        self.connect((self.blocks_magphase_to_complex_0, 0), (self.iio_pluto_sink_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.blocks_magphase_to_complex_0, 1))
        self.connect((self.blocks_stream_to_vector_0, 0), (self.blocks_keep_one_in_n_0, 0))
        self.connect((self.dc_blocker_xx_0, 0), (self.blocks_multiply_const_vxx_0, 0))
        self.connect((self.uhd_usrp_source_0, 1), (self.blocks_interleave_0, 1))
        self.connect((self.uhd_usrp_source_0, 0), (self.blocks_interleave_0, 0))

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.iio_pluto_sink_0.set_params(self.f, self.samp_rate, 20000000, 30.0, '', True)
        self.uhd_usrp_source_0.set_samp_rate(self.samp_rate)

    def get_f(self):
        return self.f

    def set_f(self, f):
        self.f = f
        # self.iio_pluto_sink_0.set_params(self.f, self.samp_rate, 20000000, 30.0, '', True)
        self.iio_pluto_sink_0.set_single_param("out_altvoltage1_TX_LO_frequency",self.f)
        self.uhd_usrp_source_0.set_center_freq(self.f, 0)
        self.uhd_usrp_source_0.set_center_freq(self.f, 1)
        # print(self.uhd_usrp_source_0.get_sensor("lo_locked"))

    def get_N(self):
        return self.N

    def set_N(self, N):
        self.N = N

    def jmf_server(self):
        sock=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(('localhost', 5556))
        print("Server running")
        sock.listen(1)
        conn, addr = sock.accept()
        with conn:
            print('connected from ',addr)
            while True:
                 data=conn.recv(1)
                 print(data)
                 if '+' in str(data):
                    self.f=self.f+1000000
                 if '-' in str(data):
                    self.f=self.f-1000000
                 if '0' in str(data):
                    self.f=int(650e6)
                 if '.' in str(data):
                    self.f=self.f
                    print('Reprogram')
                 if 'q' in str(data):
                    print('Bye')
                    sock.shutdown(socket.SHUT_RDWR)
                    sock.close()
                 print(self.f)
                 self.set_f(self.f)

def main(top_block_cls=t, options=None):
    tb = top_block_cls()
    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()
        sys.exit(0)

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    tb.start()
    print("Starting server")
    threading.Thread(target=tb.jmf_server).start()

    try:
        input('Press Enter to quit: ')
    except EOFError:
        pass
    tb.stop()
    tb.wait()

if __name__ == '__main__':
    main()
