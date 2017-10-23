clf;
hold all;
f1 = abs(fft(w1)).^2;
a1 = [0;-diff(diff(asinh(f1)));0];
plot(f1);
plot(2000*a1);
axis tight
%plot(a1);
%axis([0 65536 -20 22000]);
%plot(10000*diff(diff(asinh(f1))));
%plot(f1.*[0;exp(diff(diff(log(f1))));0]);

hold off;