classdef prtClassBinaryToMaryOneVsAll < prtClass & prtActionBig
    % prtClassBinaryToMaryOneVsAll  M-Ary Emulation Classifier
    %
    %    CLASSIFIER = prtClassBinaryToMaryOneVsAll returns a M-ary "one
    %    versus all" classifier. A one versus all classifier utilizes a
    %    binary classifier to make M-ary decisions. For all M classes, it
    %    selects each class, and makes a binary comparison to all the
    %    others.
    %
    %    CLASSIFIER = prtClassBinaryToMaryOneVsAll(PROPERTY1, VALUE1, ...)
    %    constructs a prtClassBinaryToMaryOneVsAll object CLASSIFIER with
    %    properties as specified by PROPERTY/VALUE pairs.
    %
    %    A prtClassBinaryToMaryOneVsAll object inherits all properties from the
    %    abstract class prtClass. In addition is has the following
    %    properties:
    %
    %    baseClassifier - The classifier to be used to make the binary
    %                  decisions. Must be a prtClass object, and defaults 
    %                  to a prtClassLogisticDiscriminant classifier.
    % 
    %    A prtClassBinaryToMaryOneVsAll object inherits the TRAIN, RUN,
    %    CROSSVALIDATE and KFOLDS methods from prtAction. It also inherits
    %    the PLOT method from prtClass.
    %
    %    Example:
    %
    %     TestDataSet = prtDataGenMary;      % Create some test and 
    %     TrainingDataSet = prtDataGenMary;  % training data
    %     classifier = prtClassBinaryToMaryOneVsAll;   % Create a classifier
    %     classifier.baseClassifier = prtClassGlrt;    % Set the binary 
    %                                                  % Classifier
    %     % Set the internal Decider
    %     classifier.internalDecider = prtDecisionMap;
    %
    %     classifier = classifier.train(TrainingDataSet);    % Train
    %     classes    = run(classifier, TestDataSet);         % Test
    %
    %     % Evaluate, plot results
    %     percentCorr = prtScorePercentCorrect(classes.getX,TestDataSet.getTargets)
    %     classifier.plot;
    %
    %    See also prtClass, prtClassLogisticDiscriminant, prtClassBagging,
    %    prtClassMap, prtClassCap, prtClassBinaryToMaryOneVsAll, prtClassDlrt,
    %    prtClassPlsda, prtClassFld, prtClassRvm, prtClassGlrt,  prtClass







    properties (SetAccess=private)
        name = 'M-Ary Emaulation One vs. All'  % M-Ary Emaulation One vs. All
        nameAbbreviation = 'OneVsAll'  % OVA
        isNativeMary = true;  % True
    end
    
    properties
        baseClassifier = prtClassLogisticDiscriminant; % The classifier to be used
    end
    
    methods
        
        function Obj = prtClassBinaryToMaryOneVsAll(varargin)
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
        end
        
        function Obj = set.baseClassifier(Obj,classifier)
            if ~isa(classifier,'prtClass')
                error('prt:prtClassBinaryToMaryOneVsAll','baseClassifier must be a subclass of prtClass, but classifier provided was a %s',class(classifier));
            end
            Obj.baseClassifier = classifier;
        end
    end
    
    methods (Access = protected,Hidden = true)
        
        function Obj = trainAction(Obj,dataSet)
            % Repmat the Classifier objects to get one for each class
            Obj.nameAbbreviation = sprintf('OneVsAll_{%s}',Obj.baseClassifier(1).nameAbbreviation);
            Obj.baseClassifier = repmat(Obj.baseClassifier(:), (dataSet.nClasses - length(Obj.baseClassifier)+1),1);
            Obj.baseClassifier = Obj.baseClassifier(1:dataSet.nClasses);
            
            actuallyShowProgressBar = Obj.showProgressBar && (dataSet.nClasses > 1);
            
            if actuallyShowProgressBar
                waitBarObj = prtUtilProgressBar(0,'Training M-Ary Emulation Classifier (One vs. All)','autoClose',true);
            end
            
            for iY = 1:dataSet.nClasses
                if actuallyShowProgressBar
                    waitBarObj.update((iY-1)/dataSet.nClasses);
                end
                
                % Replace the targets with binary targets for this class
                cDataSet = dataSet.setTargets(dataSet.getTargetsAsBinaryMatrix(1:dataSet.nObservations,iY));
                % We need the classifier to act like a binary and we dont 
                % want a bunch of DataSets lying around
                Obj.baseClassifier(iY).verboseStorage = false;
                Obj.baseClassifier(iY).twoClassParadigm = 'binary';
                
                % Train this Classifier
                Obj.baseClassifier(iY) = train(Obj.baseClassifier(iY), cDataSet);
            end
            if actuallyShowProgressBar
                waitBarObj.update(1);
            end
            
        end

        function Obj = trainActionBig(Obj,dataSetBig)
            % Repmat the Classifier objects to get one for each class
            
            Obj.nameAbbreviation = sprintf('OneVsAll_{%s}',Obj.baseClassifier(1).nameAbbreviation);
            Obj.baseClassifier = repmat(Obj.baseClassifier(:), (dataSetBig.nClasses - length(Obj.baseClassifier)+1),1);
            Obj.baseClassifier = Obj.baseClassifier(1:dataSetBig.nClasses);
            
            actuallyShowProgressBar = Obj.showProgressBar && (dataSetBig.nClasses > 1);
            
            if actuallyShowProgressBar
                waitBarObj = prtUtilProgressBar(0,'Training M-Ary Emulation Classifier (One vs. All)','autoClose',true);
            end
            
            for iY = 1:dataSetBig.nClasses
                if actuallyShowProgressBar
                    waitBarObj.update((iY-1)/dataSetBig.nClasses);
                end
                
                mapper = prtPreProcFunctionTargets('transformationFunction',@(y)y == dataSetBig.uniqueClasses(iY));
                mapper = mapper.trainBig(dataSetBig);
                dsTemp = mapper.runBig(dataSetBig);
                
                % want a bunch of DataSets lying around
                Obj.baseClassifier(iY).verboseStorage = false;
                Obj.baseClassifier(iY).twoClassParadigm = 'binary';
                
                % Train this Classifier
                Obj.baseClassifier(iY) = trainBig(Obj.baseClassifier(iY), dsTemp);
            end
            if actuallyShowProgressBar
                waitBarObj.update(1);
            end
            
        end
        
        function DataSetOut = runAction(Obj,dataSet)
            DataSetOut = dataSet;
            DataSetOut.X = nan(DataSetOut.nObservations,1);
            
            for iY = 1:length(Obj.baseClassifier)
                cOutput = run(Obj.baseClassifier(iY), dataSet);
                
                DataSetOut = DataSetOut.setObservations(cOutput.getObservations(),1:DataSetOut.nObservations,iY);
            end
        end
        
    end
    
end
