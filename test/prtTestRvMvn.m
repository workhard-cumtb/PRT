function result = prtTestRvMvn
result = true;

% Test the basic operation
dataSet    = prtDataGenUnimodal;
dataSetOneClass = prtDataSetClass(dataSet.getObservationsByClass(1));

try
    RV = prtRvMvn;                       % Create a prtRvMvn object
    RV = RV.mle(dataSetOneClass.getX);   % Compute the maximum
catch
    disp('prtRvMvn basic operation fail')
    result= false;
end

if abs(RV.mean - [2 2] ) > .1
    result = false;
end
% make sure none of these disp out
try
    RV.plotPdf                           % Plot the pdf
    close
catch
    disp('prtRvMvn plot pdf fail')
    result = false;
    close
end

RVspec = prtRvMvn;
% Check that I can specify the mean and covar
try
    RVspec.mean = [1 2];                 % Specify the mean
    RVspec.covariance = [2 -1; -1 2] ;    % Specify the covariance
catch
    disp('prtRvMvn mean covar set fail')
    result=  false;
end

% check the draw function
try
    sample = RVspec.draw(1);
catch
    disp('prtRvMvn draw fail')
end

if( size(sample) ~= [1 2])
    disp('prtRvMvn sample size incorrect')
end

% Check that we can set the covar structure
try
    RV.covarianceStructure = 'Full';
    RV.covarianceStructure = 'Spherical';
    RV.covarianceStructure = 'Diagonal';
catch
    disp('prtRvMvn covar structure set fail')
end

% Add a check here to make sure the covar is actually diagonal

% check the pdf and cdf functions
try
    val1 = RV.pdf([ 0 0 ]);
    %val2 = RV.cdf([ 0 0]); % Cdf does not work in 2D
catch
    disp('prtRvMvn pdf/cdf fail')
    result = false;
end

% Make sure we error out on size mismatch
try
    val1 = RV.pdf(0);
    val2 = RV.cdf(0);
    disp('prtRvMvn pdf/cdf size check fail')
    result = false;
catch
    % noop;
end
