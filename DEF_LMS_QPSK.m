%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation of a communication system using decision-feedback equalizer
% with the LMS algorithm in order to mitigate the frequency selective
% effects of the wireless channel.
%
% Author: Pedro Ivo da Cruz
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear variables; %close all;

%% Simulation Parameters:
M = 4;          % Ordem da modula��o QPSK
NTbits = 1e8;   % N�mero total de bits a serem transmitidos
Nbits = 1e4;    % N�mero de bits a serem transmitidos por realiza��o
Ntr = 1000;     % Comprimento da sequ�ncia de treinamento em s�mbolos
Ntrials = NTbits/Nbits; % N�mero total de realiza��es
Ns = Nbits/log2(M);
% u = 0.0001;

%% QPSK Modulation:
hMod = comm.RectangularQAMModulator( ...
    'ModulationOrder', M, ...
    'BitInput', true, ...
    'NormalizationMethod', 'Average power');
hDemod = comm.RectangularQAMDemodulator( ...
    'ModulationOrder', M, ...
    'BitOutput', true, ...
    'NormalizationMethod', 'Average power');

%% Channels parameters:
SNR = 0:2:30;           % Signal-to-noise Ratio for simulation
L = 6;                  % Channel length
pp = exp(-(0:L-1)/2);   % Channel power profile with exponential decay with factor 2
pp = pp.'/sum(pp);      % Normalize to make the total power 1;

%% Initializations:
hError = comm.ErrorRate('ResetInputPort', true);
NSNR = length(SNR);
berB = zeros(NSNR, 1);
berE = zeros(NSNR, 1);
ecma = zeros(Ns, 1);

%% Simulation:
cont = 0;
barStr = 'SIM_QPSK_THP.m';
progbar = waitbar(0, 'Initializing waitbar...', ...
    'Name', barStr);

fprintf('Simula��o iniciada\n')

for iSNR = 1:NSNR
    
    berBtrial = 0;
    berEtrial = 0;
    ecmatrial = zeros(Nbits, 1);
    Ph = 0;
    
    for iReal = 1:Ntrials
        
        %% Transmitter:
        xa = randsrc(Nbits, 1, [0 1]);          % Information bit stream
        xamod = step(hMod, xa);                 % Modulate
        
        %%  Channel
        hab = hba;                                % Reciprocal channel
        ybch = filter(hab, 1, xamod);             % Apply fading
        ybch = awgn(ybch, SNR(iSNR), 'measured'); % AWGN
        
        %% Receiver:
        % DFE:
        
        
        % Demodulate:
        xbdemod = step(hDemod, ybd);
        
        % CMA Receiver:
%         [w, ytemp, etemp] = cmaEqualizer(yech, u, 3*L, 0); % Apply CMA Equalizer
%         yeeq = filter(w(:, end), 1, [yech; zeros(floor(3*L/2)-3, 1)]);
%         yeeq(1:floor(3*L/2)-3) = [];
%         yeeq = filter(w(:, end), 1, yech);
%         xedemod = step(hDemod, yeeq); % Demodula
        
        
        %% Performance Evaluation
        % BER in B:
        [~, bertemp] = biterr(xbdemod, xa);
        berB(iSNR) = berB(iSNR) + bertemp;
        
        % CMA convergence:
%         ecmatrial = ecmatrial + etemp.^2;
        
        % Simulation progress:
        cont = cont + 1;
        % Update bar:
        prog = cont/(Ntrials*NSNR);
        perc = 100*prog;
        waitbar(prog, progbar, sprintf('%.2f%% Conclu�do', perc));
        
    end
    
end

berB = berB/Ntrials;
ecma = ecma/Ntrials;

close(progbar)

EbNo = SNR - 10*log10(log2(M));
% BER te�rica de um sistema QAM
% berTheory = berawgn(EbNo, 'qam', M);
berTheory = berfading(EbNo, 'qam', M, 1);
% berTheory = berawgn(EbNo, 'psk', M, 'nondiff');

% Plota os resultados
figure
semilogy(SNR, berB, 'bo--');
hold on;
semilogy(SNR, berE, 'ro--');
semilogy(SNR, berTheory, 'kx-');
legend('Alice', 'Eve', 'Theory');
xlabel('SNR (dB)');
ylabel('BER');
%axis([EbNo(1) EbNo(end) 0.0001 1]);
grid on;

figure
plot(10*log10(ecma));

% scatterplot(yach)

% fileStr = ['Resultados/THPrecoding_EveMODAdder_Nch' num2str(L)];

% Salva dados para posterior utiliza��o:
% save(fileStr, ...
%     'berB', 'berE', 'ecma', 'SNR', 'EbNo', 'L');