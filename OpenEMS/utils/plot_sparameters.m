function plot_sparameters(results)
%PLOT_SPARAMETERS Plot S-parameters from simulation results
%
%   plot_sparameters(results)
%
%   Creates comprehensive plots of S-parameters including magnitude,
%   phase, and Smith chart representations.
%
%   Inputs:
%       results - Results structure from openems_import_simulate
%
%   Author: Generated for Interdigital Bandpass Filter Project

    freq_ghz = results.frequency / 1e9; % Convert to GHz for plotting
    
    % Create figure with subplots
    figure('Position', [100 100 1200 800]);
    
    % S-parameters magnitude plot
    subplot(2, 3, 1);
    plot(freq_ghz, 20*log10(abs(results.S11)), 'b-', 'LineWidth', 2);
    hold on;
    plot(freq_ghz, 20*log10(abs(results.S21)), 'r-', 'LineWidth', 2);
    plot(freq_ghz, 20*log10(abs(results.S12)), 'g--', 'LineWidth', 1.5);
    plot(freq_ghz, 20*log10(abs(results.S22)), 'm--', 'LineWidth', 1.5);
    grid on;
    xlabel('Frequency (GHz)');
    ylabel('Magnitude (dB)');
    title('S-Parameters Magnitude');
    legend('S11', 'S21', 'S12', 'S22', 'Location', 'best');
    ylim([-60, 5]);
    
    % S-parameters phase plot
    subplot(2, 3, 2);
    plot(freq_ghz, unwrap(angle(results.S11))*180/pi, 'b-', 'LineWidth', 2);
    hold on;
    plot(freq_ghz, unwrap(angle(results.S21))*180/pi, 'r-', 'LineWidth', 2);
    plot(freq_ghz, unwrap(angle(results.S12))*180/pi, 'g--', 'LineWidth', 1.5);
    plot(freq_ghz, unwrap(angle(results.S22))*180/pi, 'm--', 'LineWidth', 1.5);
    grid on;
    xlabel('Frequency (GHz)');
    ylabel('Phase (degrees)');
    title('S-Parameters Phase');
    legend('S11', 'S21', 'S12', 'S22', 'Location', 'best');
    
    % Smith chart for S11
    subplot(2, 3, 3);
    plot_smith_chart();
    hold on;
    plot(real(results.S11), imag(results.S11), 'b-', 'LineWidth', 2);
    title('S11 Smith Chart');
    axis equal;
    grid on;
    
    % Return loss and insertion loss
    subplot(2, 3, 4);
    plot(freq_ghz, -20*log10(abs(results.S11)), 'b-', 'LineWidth', 2);
    hold on;
    plot(freq_ghz, -20*log10(abs(results.S21)), 'r-', 'LineWidth', 2);
    grid on;
    xlabel('Frequency (GHz)');
    ylabel('Loss (dB)');
    title('Return Loss and Insertion Loss');
    legend('Return Loss (|S11|)', 'Insertion Loss (|S21|)', 'Location', 'best');
    
    % Group delay
    subplot(2, 3, 5);
    if length(freq_ghz) > 1
        gd_s21 = -diff(unwrap(angle(results.S21))) ./ (2*pi*diff(results.frequency)) * 1e9; % ns
        plot(freq_ghz(1:end-1), gd_s21, 'r-', 'LineWidth', 2);
        grid on;
        xlabel('Frequency (GHz)');
        ylabel('Group Delay (ns)');
        title('Group Delay S21');
    end
    
    % VSWR
    subplot(2, 3, 6);
    vswr = (1 + abs(results.S11)) ./ (1 - abs(results.S11));
    semilogy(freq_ghz, vswr, 'b-', 'LineWidth', 2);
    grid on;
    xlabel('Frequency (GHz)');
    ylabel('VSWR');
    title('Voltage Standing Wave Ratio');
    ylim([1, 10]);
    
    % Add main title
    sgtitle(sprintf('OpenEMS Simulation Results - %s Layout', results.format_type), 'FontSize', 14, 'FontWeight', 'bold');
    
    % Print summary statistics
    fprintf('\n=== Simulation Results Summary ===\n');
    freq_center_idx = round(length(results.frequency)/2);
    fprintf('Center frequency: %.2f GHz\n', freq_ghz(freq_center_idx));
    fprintf('|S11| at center: %.2f dB\n', 20*log10(abs(results.S11(freq_center_idx))));
    fprintf('|S21| at center: %.2f dB\n', 20*log10(abs(results.S21(freq_center_idx))));
    fprintf('VSWR at center: %.2f\n', vswr(freq_center_idx));
    
    % Find -3dB bandwidth
    s21_db = 20*log10(abs(results.S21));
    max_s21 = max(s21_db);
    bw_indices = find(s21_db >= max_s21 - 3);
    if ~isempty(bw_indices)
        bw_ghz = freq_ghz(bw_indices(end)) - freq_ghz(bw_indices(1));
        fprintf('-3dB Bandwidth: %.2f MHz\n', bw_ghz * 1000);
        fprintf('Center frequency (from BW): %.2f GHz\n', (freq_ghz(bw_indices(end)) + freq_ghz(bw_indices(1)))/2);
    end
end

function plot_smith_chart()
    % Draw Smith chart circles
    theta = 0:pi/100:2*pi;
    
    % Outer circle
    plot(cos(theta), sin(theta), 'k-', 'LineWidth', 1);
    hold on;
    
    % Constant resistance circles
    r_circles = [0.2, 0.5, 1, 2, 5];
    for r = r_circles
        center = r/(1+r);
        radius = 1/(1+r);
        x = center + radius*cos(theta);
        y = radius*sin(theta);
        plot(x, y, 'k--', 'LineWidth', 0.5);
    end
    
    % Constant reactance arcs
    x_arcs = [0.2, 0.5, 1, 2, 5];
    for x = x_arcs
        if x > 0
            center_y = 1/x;
            radius = 1/x;
            % Upper arc
            phi = asin(min(1, 1/radius)):pi/100:pi-asin(min(1, 1/radius));
            arc_x = 1 + radius*cos(phi);
            arc_y = center_y + radius*sin(phi);
            plot(arc_x, arc_y, 'k:', 'LineWidth', 0.5);
            
            % Lower arc
            arc_y = -center_y + radius*sin(phi);
            plot(arc_x, arc_y, 'k:', 'LineWidth', 0.5);
        end
    end
    
    % Center lines
    plot([-1 1], [0 0], 'k-', 'LineWidth', 0.5);
    plot([0 0], [-1 1], 'k-', 'LineWidth', 0.5);
    
    axis([-1.1 1.1 -1.1 1.1]);
    axis equal;
end