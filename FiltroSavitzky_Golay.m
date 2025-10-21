% ----- PROGRAMA FILTRO de Savitzky-Golay  ------
% *** Distribución Temporal uniforme Confirmado de inicio x Osciloscopio***

clear all; % Borro todos los valores que pudiera tener las variables de calculos anteriores en MATLAB
clc; % Limpio pantalla comandos
close all;    % Cierro todas las figuras abiertas

% Carga datos (cargo como líneas; abro archivo modo lectura:
fid = fopen('d:\Documents\EST\Combustion\TP-Concurso\Rc4-4\WaveData96.csv', 'r'); %Presión CH1
fid1 = fopen('d:\Documents\EST\Combustion\TP-Concurso\Rc4-4\WaveData97.csv', 'r'); % Pos Angular CH2

% Crear carpeta si no existe:
output_folder = 'D:\Documents\EST\Combustion\TP-Concurso\Rc4-4\FigurasSavitzky-Golay';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Leo 3 primeras líneas Presión - Pos Angular:
line1 = fgetl(fid); %Base de tiempo
line2 = fgetl(fid); %Base Tensión
line3 = fgetl(fid); %Size
line11 = fgetl(fid1); %Base de tiempo
line22 = fgetl(fid1); %Base Tensión
line33 = fgetl(fid1); %Size = anterior x osciloscopio 2 canales

% Extraigo base de tiempo:
timebase_str = regexp(line1, 'timebase=(\d+)', 'tokens');
timebase = str2double(timebase_str{1})*1e-9/10;  % Resultado: 20000000000*1e-9 ps ? s = 2 (10 divisiones en osciloscopio [ms])
timebase_str1 = regexp(line11, 'timebase=(\d+)', 'tokens');
timebase1 = str2double(timebase_str1{1})*1e-9/10; % Osiloscopio registra en [ms]

% Extraigo base de Tensión:
voltbase_str = regexp(line2, 'voltbase=(\d+)', 'tokens');
voltbase = str2double(voltbase_str{1})*1e-3;  % Resultado: 500000*1e-3 uV ? V (osciloscopio informa CSV en [mV])
voltbase_str1 = regexp(line22, 'voltbase=(\d+)', 'tokens');
voltbase1 = str2double(voltbase_str1{1})*1e-3;

% Extraigo tamaño muestral:
size_str = regexp(line3, 'size=(\d+)', 'tokens');
size_val = str2double(size_str{1});  % Resultado: 4064 muestras

% Leo datos numéricos desde 4ta línea:
data = textscan(fid, '%f%f', size_val, 'Delimiter', ',', 'CollectOutput', true);
fclose(fid);
data1 = textscan(fid1, '%f%f', size_val, 'Delimiter', ',', 'CollectOutput', true);
fclose(fid1);

% Separo columnas:
raw = data{1};
t_raw = raw(:,1); % tiempo
p_raw = raw(:,2); % presión
raw1 = data1{1};
t_raw1 = raw1(:,1); % tiempo
a_raw = raw1(:,2); % ángulo
a_raw(a_raw < 0) = 0; % Reemplazo valores negativos x "0"

% Aplico correcciones (base de tiempo y Tensión):
t = t_raw / timebase;  % tiempo [s]
p = p_raw / voltbase;  % presión [V]
t1 = t_raw1 / timebase1;  % tiempo [s]
a = a_raw / voltbase1;  % presión [V]

% Aplico filtro Savitzky-Golay:
% Presión:
orden = 2;     % Grado del polinomio (suaviza sin perder forma)
ventana = 151; % Tamaño de ventana (debe ser impar y < length(p))
p_suave = sgolayfilt(p, orden, ventana);
% Ángulo:
orden1 = 3;   % Grado del polinomio (suaviza sin perder forma)
ventana1 = 11; % Tamaño de ventana (debe ser impar y < length(a))
a_suave = sgolayfilt(a, orden1, ventana1);

% VALIDACIÓN FILTRADO P:
% Derivada 1era P (velocidad de cambio)
dp = diff(p) ./ diff(t);             % Original
dp_suave = diff(p_suave) ./ diff(t); % Filtrada
% Aplico filtro Savitzky-Golay derivada 1º:
% Presión:
orden2 = 2;     % Grado del polinomio (suaviza sin perder forma)
ventana2 = 151; % Tamaño de ventana (debe ser impar y < length(p))
dp_suave1 = sgolayfilt(dp_suave, orden2, ventana2);
% Derivada 2da P (curvatura o concavidad)
ddp = diff(dp) ./ diff(t(2:end));             % Original
ddp_suave = diff(dp_suave) ./ diff(t(2:end)); % Filtrada
ddp_suave1 = diff(dp_suave1) ./ diff(t(2:end)); % dp1 Filtrada
% Aplico filtro Savitzky-Golay derivada 2º:
% Presión:
orden3 = 2;     % Grado del polinomio (suaviza sin perder forma)
ventana3 = 151; % Tamaño de ventana (debe ser impar y < length(p))
ddp_suave2 = sgolayfilt(ddp_suave1, orden3, ventana3); %ddp2 filtrada

% VALIDACIÓN FILTRADO a:
umbral = 0.65 * max(a);  % Detecto picos mayores al 65% máximo
[pk_raw, loc_raw] = findpeaks(a, 'MinPeakHeight', umbral); % Detecto picos en a
[pk_fil, loc_fil] = findpeaks(a_suave, 'MinPeakHeight', umbral); %Detecto picos en a filtrado
%Solo picos c/ valor arbitrario:
a_suavex = zeros(size(a_suave)); % Inicio con ceros.
a_suavex(loc_fil) = 8;  % Asigno valor fijo 8 a posición de picos.
% Comparo tiempos de detección
t_raw = t(loc_raw); %cruda
t_fil = t(loc_fil); %filtrada

% DETECCIÓN VALORES MÁXIMOS en P_suave (filtrada) y registro tiempos:
umbralp_suave = 0.90 * max(p_suave);  % Detecto picos mayores al 90% máximo
[pk, loc] = findpeaks(p_suave, 'MinPeakHeight', umbralp_suave);  % Detecto picos
t_picos = t(loc);  % Tiempos en [s] donde ocurren los picos Presión
idx_central = round(length(t_picos)/2);  % Índice pico central
t_central = t_picos(idx_central);        % Tiempo pico central
for i = 1:length(t_picos) % Muestro valores de picos [s] y [V]
    fprintf('Pico presión %d: t = %.6f [s], valor = %.3f [V]\n', i, t_picos(i), pk(i));
end
% Cálculos estadísticos Presión:
pk_prom = mean(pk); % Valor promedio picos Presión
pk_std = std(pk);   % Desvío estándar picos Presión
fprintf('\nValor promedio picos Presión: %.3f [V]\n', pk_prom);
fprintf('Desvío estándar picos Presión: %.3f [V]\n', pk_std);
% Diferencias entre picos presión:
dt = diff(t_picos); % Duración total intervalo [s]
disp('Diferencias entre picos de Presión consecutivos [s]:');
disp(dt);
% Promedio de diferencias:
dt_prom = mean(dt);
dt_std_p = std(dt);
Ts = t(2) - t(1); % Tiempo de muestreo [s] global Ts = median(diff(t));
Fs = 1 / Ts;      % Frecuencia de muestreo [Hz]
fprintf('Tiempo muestreo Global Ts: %.7f [s]\n', Ts);
fprintf('Frecuencia muestreo Fs: %.2f [Hz]\n', Fs);
t_izq = t_central - dt_prom/2; % Para truncado izquierdo
t_der = t_central + dt_prom/2; % Para truncado derecho
fprintf('Promedio diferencias temporales Presión: %.4f [s]\n', dt_prom);
fprintf('Desvío estándar diferencias temporales Presión: %.4f [s]\n', dt_std_p);
% Conversión a RPM
rpm = (60 / dt_prom) / 2;
fprintf('RPM Ciclo Picos Presión Filtrados: %.2f [rpm]\n', rpm);
% Truncado de Vectores:
idx_truncado = (t >= t_izq) & (t <= t_der);
t_trunc = t(idx_truncado);
a_trunc = a_suavex(idx_truncado);
p_trunc = p_suave(idx_truncado);

% ANÁLISIS DE TIEMPOS ANGULARES:
%Filtrado eventos con valor 8 V:
idx_8 = find(a_suavex == 8);  % Índices donde el valor es 8
t_8 = t(idx_8);               % Tiempos correspondientes
% Calculo tiempo de muestreo típico:
dt_8 = diff(t_8);     % Diferencias tiempo entre eventos con valor 8
%fprintf('dt_8 [s]: %.6f\n', dt_8);
dt_inicio = dt_8(1:5);  % Primeros 5 valores
%fprintf('dt_inicio [s]: %.6f\n', dt_inicio);
% Detecto grupos de 5 eventos consecutivos con dt ? Ts/2
umbral = mean(dt_inicio) * .6;  % Umbral superior promedio inicial
idx_denso = find(dt_8 < umbral);  % Índices donde el muestreo es más rápido
%fprintf('idx_denso [s]: %.0f\n', idx_denso);
centros = [];  % Inicializo vector de centros
% Busqueda de puntos mayor densidad:
for i = 1:length(idx_denso)-3
    grupo = idx_denso(i:i+3);
    if all(diff(grupo) == 1)  % Verifico que son consecutivos
        centro_idx8 = grupo(2)+1;        % Índice central en idx_8
        centro_real = idx_8(centro_idx8);  % Índice real en a_suavex
        centros(end+1) = centro_real;
    end
end
% Reasigno valor en centros detectados a 10:
a_suavex_mod = a_suavex;        % Copia del original
a_suavex_mod(centros) = 10;     % Asigno nuevo valor arbitrario 10
a_trunc1 = a_suavex_mod(idx_truncado);
% Validación tiempos: veo en función de optimizar el filtro:
%disp('Tiempos donde a_suavex == 8:');
%disp(t_8);
%disp('Diferencias de tiempo entre eventos:');
%disp(dt_8);

% BUSQUEDA DONDE a_suavex =10:
idx_10 = find(a_suavex_mod == 10);  % Índices donde se asignó el valor 10
t_10 = t(idx_10);  % Tiempos en segundos donde a_suavex == 10
dt_10 = diff(t_10);  % Diferencias entre tiempos consecutivos
% Muestro valores, X y s:
disp('Tiempos donde a_suavex_mod == 10:');
disp(t_10);
disp('Diferencias temporales entre eventos:');
disp(dt_10);
dt_prom_a = mean(dt_10);
dt_std_a = std(dt_10);
fprintf('Promedio diferencia temporal angular: %.6f [s]\n', dt_prom_a);
fprintf('Desvío estándar angular: %.6f [s]\n', dt_std_a);
% Conversión a RPM:
rpm_a = (60 / dt_prom_a) /4; % RPM promedio
fprintf('RPM Ciclo Angular: %.2f [rpm]\n', rpm_a);
rpm_as = (60 / (dt_prom_a^2)*dt_std_a) /4; % Desvío estándar en RPM
fprintf('RPM +/- : %.2f [rpm]\n', rpm_as);


% PLOTEO PRESIÓN p Fig 1:
figure;
plot(t, p, 'b-', 'DisplayName', 'Original');
hold on;
plot(t, p_suave, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Savitzky-Golay');
xlabel('Tiempo [s]');
hold on;
plot(t, a_suavex_mod, 'ko', 'MarkerSize', 1.5, 'DisplayName', 'Picos Sensor Pos. & PMS=10[V]');
ylabel('Presión [V]');
legend show;
title('Filtrado Savitzky-Golay aplicado señal exponencial', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
ylim([min([p; p_suave]) max([p; p_suave])]);  % Autoescala eje Y según datos
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
% Ejes simulados:
annotation('arrow', [0.102 .95], [0.03 0.03]);  % Flecha eje X
annotation('arrow', [0.102 0.102], [0.03 .97]);  % Flecha eje Y
saveas(gcf, fullfile(output_folder, 'Fig1_PresionOrigFil.png'));

% PLOTEO COMPARACIÓN DERIVADAS CRUDAS/FILTRADAS p Fig 2:
figure;
% Derivada 1era P
subplot(2,1,1);
plot(t(1:end-1), dp, 'b-', 'DisplayName', 'Original');
hold on;
plot(t(1:end-1), dp_suave, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Filtrada');
xlabel('Tiempo [s]');
ylabel('Derivada 1º [V/s]');
legend show;
title('Comparación derivada 1º (Velocidad cambio)S-G', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
% Derivada 2da P
subplot(2,1,2);
plot(t(2:end-1), ddp, 'b-', 'DisplayName', 'Original');
hold on;
plot(t(2:end-1), ddp_suave, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Filtrada');
xlabel('Tiempo [s]');
ylabel('Derivada 2º [V/s²]');
legend show;
title('Comparación derivada 2º (concavidad) S-G', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
saveas(gcf, fullfile(output_folder, 'Fig2_DerivadasCrudas-Filtradas.png'));

% PLOTEO DERIVADAS P 1º y 2º FILTRADAS Fig 3:
figure;
% Derivada 1era P
subplot(2,1,1);
plot(t(1:end-1), dp_suave, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Filtrada');
xlabel('Tiempo [s]');
ylabel('Derivada 1º [V/s]');
legend show;
title('Derivada 1º (Velocidad cambio)', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
% Derivada 2da P
subplot(2,1,2);
plot(t(2:end-1), ddp_suave, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Filtrada');
xlabel('Tiempo [s]');
ylabel('Derivada 2º [V/s²]');
legend show;
title('Derivada 2º (concavidad)', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
saveas(gcf, fullfile(output_folder, 'Fig3_DerivadasFiltradas.png'));

% PLOTEO PICOS Crudos y Filtradoa Fig 4:
figure;
% Señal original con picos detectados
subplot(2,1,1);
plot(t, a, 'k-', 'DisplayName', 'Original');
hold on;
plot(t_raw, pk_raw, 'ro', 'MarkerSize', 5, 'DisplayName', 'Picos detectados');
xlabel('Tiempo [s]');
ylabel('Posición angular [V]');
title('Detección picos señal original', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
legend show;
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
% Señal filtrada con picos detectados
subplot(2,1,2);
plot(t, a_suave, 'b-', 'DisplayName', 'Filtrada');
hold on;
plot(t_fil, pk_fil, 'go', 'MarkerSize', 5, 'DisplayName', 'Picos detectados');
xlabel('Tiempo [s]');
ylabel('Posición angular [V]');
title('Detección picos señal filtrada', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
legend show;
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
saveas(gcf, fullfile(output_folder, 'Fig4_PicosAngularesOrig-Fil.png'));

% PLOTEO TRUNCADO PRESIÓN x pidos P Fig 5:
figure;
plot(t_trunc, p_trunc, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Original-Filtrada');
hold on;
plot(t_trunc, a_trunc1, 'ro', 'MarkerSize', 1.5, 'DisplayName', 'Picos Sensor Pos.');
xlabel('Tiempo [s]');
ylabel('Presión [V]');
legend show;
title('Truncado P Savitzky-Golay 1 ciclo', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([min([t_trunc]-0.0005) max(t_trunc)+0.0005]); % grafico solo hasta tiempo Máx
ylim([min([p_trunc]) max([p_trunc])]);  % Autoescala eje Y según datos
saveas(gcf, fullfile(output_folder, 'Fig5_TruncadoPresionxPicos.png'));

% GRÁFICA TIPOS c/ PMS 10 Fig 6:
figure;
plot(t, a_suavex, 'ro', 'DisplayName', 'Original');
hold on;
plot(t, a_suavex_mod, 'go', 'MarkerSize', 5, 'DisplayName', 'Modificado (10 en PMS)');
xlabel('Tiempo [s]');
ylabel('Valor asignado');
legend show;
title('Reasignación de valor en centros de muestreo denso');
grid on;
saveas(gcf, fullfile(output_folder, 'Fig6_ReasignacionPMS.png'));

% PLOTEO DERIVADAS P 1º y 2º REFILTRADO dp Fig 7:
figure;
% Derivada 1era P
subplot(2,1,1);
plot(t(1:end-1), dp_suave1, 'r-', 'LineWidth', 1.5, 'DisplayName', 'ReFiltrada');
xlabel('Tiempo [s]');
ylabel('Derivada 1º [V/s]');
legend show;
title('Derivada 1º Filtrada (Velocidad cambio)', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
% Derivada 2da P
subplot(2,1,2);
plot(t(2:end-1), ddp_suave2, 'r-', 'LineWidth', 1.5, 'DisplayName', 'ReFiltrado');
xlabel('Tiempo [s]');
ylabel('Derivada 2º [V/s²]');
legend show;
title('Derivada 2º (concavidad)', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');
grid on;
% Ajustes visuales:
xlim([0 max(t)]); % grafico solo hasta tiempo Máx
set(gca, 'LineWidth', 1.5, 'TickDir', 'out'); %Lineas externas + anchas
saveas(gcf, fullfile(output_folder, 'Fig7_DerivadasFiltradas.png'));


