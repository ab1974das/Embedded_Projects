t=0:1/2048:1;
y1=sin(2*pi*t);
% subplot(2,1,1);
% plot(t,y1);

y2=sin(2*30*pi*t);
% subplot(2,1,2);
% plot(t,y2);

y3=y1+y2;
y3=((y3+2)/4)*255;
plot(t,y3);
y4=round(y3);

y8 = dec2hex(y4);
hex_cells = cellstr(y8);
string = strcat(',0x', hex_cells);
final_string = [string{:}];
final_string = final_string(2:end);
disp(final_string);
