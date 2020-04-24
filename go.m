pkg load signal
load 700_750_house_final4_with_protection.mat.gz

df=1;     % frequency sweep step (MHz)
Nf=50;    % number of frequency steps (separated by df MHz)
fs=2.7;   % acquisition sampling freq (MHz)
t=[0:length(mes1)-1]/fs;
tplot=[-10:10]/fs;  % time for plotting individual spectra
span=floor(df/fs*length(mes1));  % bin index increment every time LO increases by 1 MHz
spectrum1=zeros(floor((Nf*df+3*fs)/fs*length(mes1)),1); % extended spectral range
spectrum2=zeros(floor((Nf*df+3*fs)/fs*length(mes1)),1); % ... resulting from spectra concatenation
for f=0:Nf-1
   f
   if (max(abs(xcorr(mes1(:,f+1),mes2(:,f+1),128)))<1000)
      h=hamming(length(mes1));                                               % center of FFT in the middle
      spectrum1(f*span+1:f*span+length(mes1))=spectrum1(f*span+1:f*span+length(mes1))+h.*fftshift(fft(mes1(:,f+1))); 
      spectrum2(f*span+1:f*span+length(mes2))=spectrum2(f*span+1:f*span+length(mes2))+h.*fftshift(fft(mes2(:,f+1)));
   end
end

x=fftshift(ifft(conj(spectrum2).*(spectrum1)));
newfs=Nf*df+3*fs;
N=100;
tplot=[-N:N]/newfs;
res=abs(x(floor(length(x)/2)-N:floor(length(x)/2)+N));
plot(tplot,res/max(res)); ylim([0 0.15]); xlabel('time (us)'); ylabel('normalized |xcorr| (no unit)')
