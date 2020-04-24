clear all
more off
Nfreq=100
total_length=140000;
fs=2.7;   % acquisition sampling freq (MHz)
finc=1.0;
switch_control=0;

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

sck=socket(AF_INET, SOCK_STREAM, 0); 
server_info=struct("addr","127.0.0.1","port",5556);
connect(sck,server_info);

for m=1:100
tic 
send(sck,'0');                   % reset frequency to min value
for frequence=1:Nfreq
   sock1 = zmq_socket(ZMQ_SUB);  % socket-connect-opt-close = 130 us
   zmq_connect   (sock1,"tcp://127.0.0.1:5555");
   zmq_setsockopt(sock1, ZMQ_SUBSCRIBE, "");
   %maximum=5000;
   %while (maximum>100)
   %  total=0;
   %  while (total<total_length)
       recv=zmq_recv(sock1, total_length*8*2, 0); % *2: interleaved channels
       value=typecast(recv,"single complex"); % char -> float
   %    if ((total+length(value))<total_length)
   %      vector(total+1:total+length(value))=value;
   %    else
   %      vector(total+1:end)=value(1:total_length-total);
   %    end
   %    total=total+length(value)
   %    mes1(:,frequence)=vector(1:2:length(vector));
   %    mes2(:,frequence)=vector(2:2:length(vector));
%       length(value)
       mes1(:,frequence)=value(1:2:length(value));
       mes2(:,frequence)=value(2:2:length(value));
   %  end
     %maximum=(abs(xcorr(mes1(:,frequence),mes2(:,frequence),26)))(3);
     %if (maximum>100) printf("Restart %f\n",maximum); send(sck,'.'); pause(0.05); end
   %end
   % plot(abs(xcorr(mes1(:,frequence),mes2(:,frequence),26)))
   zmq_close (sock1);
   send(sck,'+');
%   pause(0.001)
end
toc

t=[0:length(mes1)-1]/fs;
tplot=[-10:10]/fs;  % time for plotting individual spectra
span=floor(finc/fs*length(mes1));  % bin index increment every time LO increases by 1 MHz
spectrum1=zeros(floor((finc*Nfreq+3*fs)/fs*length(mes1)),1); % extended spectral range
spectrum2=zeros(floor((finc*Nfreq+3*fs)/fs*length(mes1)),1); % ... resulting from spectra concatenation
w=hanning(length(mes1));
%figure(2)
%subplot(211)
for f=0:Nfreq-1
%   f
   spectrum1(f*span+1:f*span+length(mes1))=spectrum1(f*span+1:f*span+length(mes1))+w.*fftshift(fft(mes1(:,f+1)-mean(mes1(:,f+1)))); % center of FFT in the middle
   spectrum2(f*span+1:f*span+length(mes2))=spectrum2(f*span+1:f*span+length(mes2))+w.*fftshift(fft(mes2(:,f+1)-mean(mes2(:,f+1)))); % center of FFT in the middle
   res=abs(xcorr(mes1(:,f+1),mes2(:,f+1),10));
   % plot(tplot,res/max(res));hold on
   % plot((f*span+1:f*span+length(mes1))*finc/span,w.*abs(fftshift(fft(mes1(:,f+1)))));hold on
end

% figure
x=fftshift(ifft(conj(spectrum2).*(spectrum1)));
fs2=finc*Nfreq+3*fs;
N=100;
tplot=[-N:N]/fs2;
resfin(:,m)=abs(x(floor(length(x)/2)-N:floor(length(x)/2)+N));
plot(tplot,resfin(:,m)/max(resfin(:,m)));hold on
ylim([0 0.2])
refresh
m=m+1;
end
% send(sck,'q');
