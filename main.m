%--------------------------------------------------------------------------

%{

Authors:

1) Mr. Enrico Schiassi - PhD Student, Systems and Industrial Engineering, 
   The University of Arizona, Tucson, AZ
2) Dr. Roberto Furfaro - Professor, Systems and Industrial Engineering, 
   The University of Arizona, Tucson, AZ
3) Dr. Jeffrey S. Kargel- Senior Scientist, Planetary Science Institute, 
   Tucson, AZ

%}

%--------------------------------------------------------------------------

%{

main.m performs:

1) Remote sensing reflectance simulation given the wavelengts, water 
component concentrations, and the input listed below 

2) Water component concentrations retrievial given the observed and the
simulated remote sensing reflectance

%}

%--------------------------------------------------------------------------
%% 

clear ; clc; close all
format long

%%

% add path to the folder containing the functions and the spectra needed for the run
addpath('./functions_and_input-spectra/functions')
addpath('./functions_and_input-spectra/input-spectra')
addpath('./data')

%% Load data
%% synt. reflectance data (see paper for details)
data.syn.data = load('RrsObsSyn1.txt');  % [wavelength, ref]
data.syn.view = eps;   % [deg] spacecraft zenith angle
data.syn.sun  = 35.00; % [deg] sun zenith angle
%% hyperion data (see paper for details)
data.hyp.data = load('hyperion.txt');
data.hyp.view = 0.98;
data.hyp.sun  = 51.2;
%% EMIT data
data.pow.data = load('LakePowell_EMIT_053024.csv');
data.pow.view = 9.70;
data.pow.sun  = 27.05;

data.im1.label = "Imja 2023-06-05";
data.im1.data = load('EMIT_L2A_RFL_001_20230605T045030_2315604_004_spectrum.csv').';
data.im1.data = data.im1.data(1:5:end,1:2:3);  % Take 2nd row from file
data.im1.view = 7.75;
data.im1.sun  = 18.9;
data.im1.colorA = '#4E79A7';
data.im1.colorB = '#849db1';


data.im2.label = "Imja 2023-08-31";
data.im2.data = load('EMIT_L2A_RFL_001_20230831T030641_2324302_015_spectrum.csv').';
data.im2.data = data.im2.data(1:5:end,1:2:3);  % Take 2nd row from file
data.im2.view = 8.41;
data.im2.sun  = 47.76;
data.im2.colorA = '#F28E2B';
data.im2.colorB = '#FBB04e';

data.im3.label = "Imja 2024-02-27";
data.im3.data = load('EMIT_L2A_RFL_001_20240227T034910_2405803_005_spectrum.csv').';
data.im3.data = data.im3.data(:,1:2:3);
data.im3.view = 7.85;
data.im3.sun  = 52.41;
data.im3.colorA = '#59A14F';
data.im3.colorB = '#8CD17D';

% Plot data
figure(1); hold on
plot(data.im1.data(:,1),data.im1.data(:,2), 'Color', data.im1.colorA, 'Linewidth', 3)
% plot(data.im1.data(:,1),data.im1.data(:,2), ':o', 'Color', data.im1.colorB, 'Linewidth', 3)
plot(data.im2.data(:,1),data.im2.data(:,2), 'Color', data.im2.colorA, 'Linewidth', 3)
% plot(data.im2.data(:,1),data.im2.data(:,2), ':o', 'Color', data.im2.colorB, 'Linewidth', 3)
% plot(data.im3.data(:,1),data.im3.data(:,2), 'Color', data.im3.colorA, 'Linewidth', 3)
% plot(data.im3.data(:,1),data.im3.data(:,2), '--', 'Color', data.im3.colorB, 'Linewidth', 3); grid on
% title('Remote Sensing Reflectance','FontSize', 24)
xlabel('Wavelength[nm]','FontSize', 18)
ylabel('Reflectance [sr^-^1]','FontSize', 18)
legend (data.im1.label, data.im2.label)

% TODO: remove, just adding a legend since the for loop legend didn't work
% legend([data.im1.label + " Observed" data.im1.label + " GLAMBioLith" data.im2.label + " Observed" data.im2.label + " GLAMBioLith"])

xlim([data.im1.data(1,1) data.im1.data(end,1)])
print('raw', '-dpng');
figure(2)

%--------------------------------------------------------------------------
%% Input
%--------------------------------------------------------------------------

%% 0) Choose data for this MCMC run
% d = data.im2;

for d = [data.im1 data.im2] 

%% 1) Global Variables

% Warnings: 
% - 1: the names must be consistent in the main and the correspondent functions
% - 2: the tuned quantities are not part of the global variables
%

% Tune ph, CDOM, X
% global lambda S_CDOM S_X g_size type_Rrs_below zB type_case_water fA g_dd g_dsr g_dsa f_dd f_ds alpha view view_w sun sun_w rho_L P RH Hoz WV  Rrs_obs

% Tune CDOM, X, g_size 
 global C_ph lambda S_CDOM S_X type_Rrs_below zB type_case_water fA g_dd g_dsr g_dsa f_dd f_ds alpha view view_w sun sun_w rho_L P RH Hoz WV  Rrs_obs


% Tune CDOM, X
% global C_ph lambda S_CDOM S_X g_size type_Rrs_below zB type_case_water fA g_dd g_dsr g_dsa f_dd f_ds alpha view view_w sun sun_w rho_L P RH Hoz WV  Rrs_obs

% Tune g_size, X
% global C_ph C_CDOM lambda S_CDOM S_X type_Rrs_below zB type_case_water fA g_dd g_dsr g_dsa f_dd f_ds alpha view view_w sun sun_w rho_L P RH Hoz WV  Rrs_obs


% Tune X
%global C_ph C_CDOM lambda S_CDOM S_X g_size type_Rrs_below zB type_case_water fA g_dd g_dsr g_dsa f_dd f_ds alpha view view_w sun sun_w rho_L P RH Hoz WV  Rrs_obs


%% 2)  Wavelength

%{

Enter the range of wavelenght of interest.
The range allowed is the visible i.e. [400-700] [nm]
The range MUST match the range used in the data set (if inverse mode is used)

%}

FW_mode_only=0; % 0= inverse-mode, 1= forward-mode 

switch FW_mode_only
    
    case 0 % inverse mode
        % Subset to valid range
        data.RrsLam=d.data((d.data(:,1) > 400) & (d.data(:,1) < 700),:);
        lambda=data.RrsLam(:,1);             
        
    case 1 % forward mode
        
        lambda=(400:1:700)';                  
        
        % multispectral simulation
        %load MultispectralLand8bands.txt
        %lambda= MultispectralLand8bands(:,1); 
end

%% 3) Remote sensig reflectance observed/measured [1/sr]

switch FW_mode_only
    
    case 0 % inverse mode
        
        Rrs_obs=data.RrsLam(:,2); 
        
        
    case 1 % forward mode
        
        Rrs_obs= zeros(size(lambda));
end


%% 4) Case Water Selection

type_case_water=2; % 1=case-1 water; 2=case-2 water


%% 4) Angles

% Enter the view (camera) and the sun angles [degrees] - zenith angles

view=d.view;   % [deg]
sun=d.sun;    % [deg]


%% 5) Water component concentrations

% Enter the water component concentratios 

% Phytoplankton 
C_ph = eps    ;                 % [mg/m^3]  

% CDOM
C_CDOM=0.0001  ;                   % [mg/m^3]  
S_CDOM =-0.0002*C_CDOM + 0.0095;   % slope for the a_CDOM(lambda) modeling

% SPM
C_X = 2.5 ;                      % [g/m^3]
S_X= 0.0116;                     % slope for the a_X(lambda) modeling
g_size_microm= 50;               % [�m]       Grain size in [�m], default 33.6 [�m]  
g_size=g_size_microm*10^(-6);    % [m]        Grain size in [m]


%% 6) Input for the Remote Sensing Reflectance [1/sr] 

% Bottom contribution

% Water column contribution: select deep water or shallow water
type_Rrs_below=0; % 0=deep water; 1=shallow water


% Bottom depth 
zB=4.00; % [m] 


% areal fraction of bottom surface
fA0=0; % constant 
fA1=0; % sand
fA2=1; % sediment
fA3=0; % Chara contraria
fA4=0; % Potamogeton perfoliatus
fA5=0; % Potamogeton pectinatus
fA= [fA0,fA1,fA2,fA3,fA4,fA5];

% Atmospheric conditions

% Irradiance intensities [1/sr]
g_dd=0.05; g_dsr=0; g_dsa=0;

% Intensities of light sources 
f_dd= 1; f_ds= 1;

% Angstrom exponent
alpha = 1.317;

% Atmospheric pressure 
P = 1013.25; % [mbar]

% Relative Humidity
RH = 0.60;

% Scale height for ozone
Hoz=0.300; % [cm]

% Scale height of the precipitable water in the atmosphere
WV= 2.500; % [cm]


%% 7) Tuned quantities

%{

 All the fit quantities must be compotents of the following vector, not
 part of the global variables

%}

% Tune ph, CDOM, X
% Fit= [C_ph, C_CDOM, C_X];

% Tune CDOM, X, g_size 
 Fit= [C_CDOM, C_X, g_size];
  
% Tune CDOM, X
%Fit= [C_CDOM, C_X];

% Tune g_size, X
% Fit= [g_size, C_X];

% Tune X
%Fit= C_X;

%--------------------------------------------------------------------------
%%
%--------------------------------------------------------------------------
%% Output
%--------------------------------------------------------------------------

%% Geometry

% compute the view (camera) and sun angles in the water [rad]; and the Fresnel coeff
[view_w,sun_w, rho_L]=Snell_law(view,sun); 

%--------------------------------------------------------------------------

switch FW_mode_only
    
    case 0 % inverse mode
        
        % Simulated remote sensing reflectance
        [Rrs0, Res0]= AOP_Rrs(Fit);
        Rrs0=real(Rrs0);
        
        %% Water component concentrations retrievial (constrained optimization framework)
        %
        % Linear Constraints: the water component concentrations are nonnegative (inquality const.)
        
        % inequalities constraints
        Aineq=-eye(size(Fit,2));
        bineq=zeros(size(Fit))';
        % equalities constraints
        Aeq=[];
        beq=[];
        % bound constraints
        lb=[]; % lower
        ub=[]; % upper
        
        % objective function -> Res = sum((Rrs_obs-Rrs).^2)
        obj=@InvModeBioLithRT_Copt;
        
        % solving linear constrained optimization problem
        [Fitret,Res]=fmincon(obj,Fit,Aineq,bineq,Aeq,beq,lb,ub);
        
        % Simulated remote sensing reflectance w/ retrieved water component concentrations via C. opt.
        [Rrs_fit, Res_fit]= AOP_Rrs(Fitret);

        %% Water component concentrations retrievial (Bayesian optimization framework)
        
        sample_size = length(lambda);  % sample size
        p = 3;                         % number of parameters to be tuned - to be set by the user
        
        type_initial_values= 1 ;       % 0= raw guess for the tuned parameters will be the initial guess for the MCMC
                                       % 1= parameters tuned via Con.Opt. will be the initial guess for MCMC
        
        switch type_initial_values

            case 0
                mse = Res0/(sample_size-p);    % estimate for the error variance
            case 1
                
                Fit=Fitret;
                mse = Res_fit/(sample_size-p); % estimate for the error variance
        end
        
        % Define the structure for the parameters to be tuned:
        % {'name' - mandatory ,initial value- mandatory, min value, max value, prior_mu, prior_sig, targetflag, localflag}
        
        % Tune ph, CDOM, X
%         params = {
%             {'C_{ph}',  Fit(1), 0}
%             {'C_{CDOM}',Fit(2), 0}
%             {'C_{X}',   Fit(3), 0}
%             };

        % Tune CDOM, X, g_size
         params = {
            {'C_{CDOM}',  Fit(1), 0,  }
            {'C_{X}',     Fit(2), 0, 300 }
            {'d [m]',     Fit(3), 0, 33.6e-06 }
            };
         
%         % Tune CDOM, X
%         params = {
%             %{'C_{ph}',  Fit(1), 0}
%             {'C_{CDOM}',Fit(1), 0, 1}
%             {'C_{X}',   Fit(2), 0, 200}
%             };

        % Tune g_size, X
%         params = {
%             
%             {'d [m]',   Fit(1), 0, 50e-05 }
%             {'C_{X}',   Fit(2), 0, 4}
%             };
        
        % Tune X
%         params = {
%         
%             {'C_{X}',   Fit, 0, 320}
%             };
        
        % set the functions and the options for the MCMC run.
        % FUNCTIONS
        %    model.ssfun    -2*log(likelihood) function
        %    model.priorfun -2*log(pior) prior function
        %    model.sigma2   initial error variance
        %    model.N        total number of observations
        %    model.S20      prior for sigma2
        %    model.N0       prior accuracy for S20
        %    model.nbatch   number of datasets
        model.ssfun = @InvModeBioLithRT_Bopt;
        model.sigma2= mse;
        model.N=sample_size;
        %
        % OPTIONS
        %    options.nsimu            number of simulations - mandatory
        %    options.qcov             proposal covariance
        %    options.method           'dram','am','dr', 'ram' or 'mh' - mandatory
        %    options.adaptint         interval for adaptation, if 'dram' or 'am' used
        %                             DEFAULT adaptint = 100
        %    options.drscale          scaling for proposal stages of dr
        %                             DEFAULT 3 stages, drscale = [5 4 3]
        %    options.updatesigma      update error variance. Sigma2 sampled with updatesigma=1
        %                             DEFAULT updatesigma=0
        %    options.verbosity        level of information printed
        %    options.waitbar          use graphical waitbar?
        %    options.burnintime       burn in before adaptation starts
        options.nsimu = 4e3;
        options.method='dram';       % dram is default
        options.updatesigma = 1;
        
        % mcmc run
        [res,chain,s2chain] = mcmcrun(model,data,params,options);
        
        % Results 
        chainstats(chain,res) % mean and std of the sampled posteriors
        [Rrs_B, Res_B]= AOP_Rrs(mean(chain)); % simulated Rrs w/ the Bayesian opt. tuned mean values
        
        % Plots
        
        % chain plots
        
        % mcmc sampling
        % figure(1); clf
        % mcmcplot(chain,[],res,'chainpanel');
        
%         % scatter plots
%         figure(2)
%         mcmcplot(chain,[],res,'pairs');
        
        % posteriors
        % figure(3)
        % mcmcplot(chain,[],res,'denspanel',2);
        
        % error std posterior
%         figure(4); clf
%         mcmcplot(sqrt(s2chain),[],[],'hist')
%         title('Error std posterior')
        
        % Remote sensing reflectance plot
        % figure(5)
        % plot(lambda,Rrs0,lambda,Rrs_fit,lambda, Rrs_B,lambda,Rrs_obs, 'Linewidth', 3); grid on
        % title('Remote Sensing Reflectance','FontSize', 24)
        % xlabel('Wavelength[nm]','FontSize', 20)
        % ylabel('Rrs [1/sr]','FontSize', 20)
        % legend ('Rrs guess', 'Rrs fit C' , 'Rrs fit B' ,'Rrs measured')
        % xlim([lambda(1) lambda(end)])

        % Compare full data range plot
        % figure(6)
        hold on
        grid on
        h=plot(d.data(:,1),d.data(:,2), 'Color', d.colorA, 'Linewidth', 3);
        plot(lambda, Rrs_B, ':o', 'Color', d.colorB, 'Linewidth', 3);
        uistack(h, "bottom")
        % title('Remote Sensing Reflectance','FontSize', 24)
        xlabel('Wavelength[nm]','FontSize', 18)
        ylabel('Reflectance [sr^-^1]','FontSize', 18)
         
        % legend (strcat(d.label, ' Observed'), strcat(d.label, ' Modeled'))
        xlim([d.data(1,1) d.data(end,1)])

        print('refplot', '-dpng');
        
    case 1 % forward mode
        
        % Simulated remote sensing reflectance
        [Rrs0, Res0]= AOP_Rrs(Fit);
        Rrs0=real(Rrs0);
        
        % Uncomment next two lines to create synt. reflectance data
        % noise=rand(size(lambda));
        % Rrs_obs_syn=Rrs0 +0.1*Rrs0 + 0.05*noise.*Rrs0;
        
        % Simulated Remote sensing reflectance plot
        figure(1)
        plot(lambda,Rrs0, 'Linewidth', 3); grid on
        title('Remote Sensing Reflectance','FontSize', 24)
        xlabel('Wavelength[nm]','FontSize', 20)
        ylabel('Rrs [1/sr]','FontSize', 20)
        xlim([lambda(1) lambda(end)])
end
end
%%
%-------------------------------------------------------------------------