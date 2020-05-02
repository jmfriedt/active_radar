clear all
close all
more off
Nfreq=80
total_length=140000;
fs=2.2;   % acquisition sampling freq (MHz)
finc=1.0; % acquisition increment (MHz)
jmf_delay=0.01; % delay in ms
switch_control=0;

if (exist ("OCTAVE_VERSION", "builtin") > 0)  % if running GNU/Octave: load toolboxes
  pkg load zeromq
  pkg load signal
  pkg load sockets

  if (switch_control==1)
    pkg load instrument-control   % switch control
    if (exist("serial") != 3)
      disp("No Serial Support");
    endif   

    s1 = serial("/dev/ttyUSB0");  % Open the port
    pause(.1);                    % Optional wait for device to wake up 
    set(s1, 'baudrate', 115200);  % communication speed
    set(s1, 'bytesize', 8);       % 5, 6, 7 or 8
    set(s1, 'parity', 'n');       % 'n' or 'y'
    set(s1, 'stopbits', 1);       % 1 or 2
    set(s1, 'timeout', 123);      % 12.3 Seconds as an example here
    srl_write(s1,"SVO 1 1\n"); pause(0.1);
  end
end

sck=socket(AF_INET, SOCK_STREAM, 0); 
server_info=struct("addr","192.168.0.165","port",5556);
connect(sck,server_info);

vector=zeros(total_length,1);  % case of SUB socket: register all services

for m=1:1
tic
send(sck,'0');
pause(jmf_delay)
for frequence=1:Nfreq
   sock1 = zmq_socket(ZMQ_SUB);  % socket-connect-opt-close = 130 us
   zmq_connect   (sock1,"tcp://192.168.0.165:5555");
   zmq_setsockopt(sock1, ZMQ_SUBSCRIBE, "");
   recv=zmq_recv(sock1, total_length*8*2, 0); % *2: interleaved channels
   vector=typecast(recv,"single complex"); % char -> float
   mes1(:,frequence)=vector(1:2:length(vector));
   mes2(:,frequence)=vector(2:2:length(vector));
   plot(abs(xcorr(mes1(:,frequence),mes2(:,frequence),26)))
   zmq_close (sock1);
   send(sck,'+');
   pause(jmf_delay)
end
toc

t=[0:length(mes1)-1]/fs;
tplot=[-10:10]/fs;  % time for plotting individual spectra
span=floor(finc/fs*length(mes1));  % bin index increment every time LO increases by 1 MHz
spectrum1=zeros(floor((finc*Nfreq+3*fs)/fs*length(mes1)),1); % extended spectral range
spectrum2=zeros(floor((finc*Nfreq+3*fs)/fs*length(mes1)),1); % ... resulting from spectra concatenation
% w=ones(length(mes1),1); 
w=hanning(length(mes1));
for f=0:Nfreq-1
   f
   spectrum1(f*span+1:f*span+length(mes1))=spectrum1(f*span+1:f*span+length(mes1))+w.*fftshift(fft(mes1(:,f+1))); % center of FFT in the middle
   spectrum2(f*span+1:f*span+length(mes2))=spectrum2(f*span+1:f*span+length(mes2))+w.*fftshift(fft(mes2(:,f+1))); % center of FFT in the middle
   % res=abs(xcorr(mes1(:,f+1),mes2(:,f+1),10));
   % plot(tplot,res/max(res));hold on
   % plot((f*span+1:f*span+length(mes1))*finc/span,w.*abs(fftshift(fft(mes1(:,f+1)))));hold on
end

x=fftshift(ifft(conj(spectrum2).*(spectrum1)));
fs2=finc*Nfreq+3*fs;
N=200;
tplot=[-N:N]/fs2;
resfin(:,m)=abs(x(floor(length(x)/2)-N:floor(length(x)/2)+N));
figure(2)
plot(tplot,resfin(:,m)/max(resfin(:,m)));hold on
axis([-1.3 1.3 0 0.2])
figure(1)
m=m+1;
end
send(sck,'q');
