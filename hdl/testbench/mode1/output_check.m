data = importdata('vectoring_out.dat');
mag_o = data(:,1);
phase_o = data(:,2);

figure_vector = figure()
plot(mag_o/2^32,'.b');
hold on; plot(phase_o/2^31, '.r');