function BlinkPercent = Quantify_percentage_blink(Events,Mask,BeginSegment,EndSegment,display)

% 
SamplesBeg = Get_samples(Events,BeginSegment)';
SamplesEnd = Get_samples(Events,EndSegment)';
if strncmpi(EndSegment,'RESP_corrected_12ms',4)
    if ~isempty(Get_samples(Events,'NO_RESP')')
        RESP = SamplesEnd; 
        SamplesEnd = []; 
        NO_RESP = Get_samples(Events,'NO_RESP')'; 
        x = [RESP; NO_RESP]; 
        SamplesEnd = sort(x); 
    end
end
% Check segment definition are consistent
if any(size(SamplesBeg)~=size(SamplesEnd))
    error('\n The number of samples for epoch begin and end differ');
elseif any((SamplesEnd-SamplesBeg)<=0)
    error('\n End samples are smaller than Begin samples')
elseif any(diff(SamplesBeg)<0)||any(diff(SamplesEnd)<0)
    error('\n Samples are not in the right order')
end

% Check for every segment the percentage of blink
BlinkPercent = zeros(length(SamplesBeg),1);
for iSegment = 1:length(SamplesBeg)
    BlinkPercent(iSegment) = sum(Mask.BlinkContinuous(SamplesBeg(iSegment):SamplesEnd(iSegment)))/(SamplesEnd(iSegment)-SamplesBeg(iSegment));
end

% Plot ot check, ifg required
if display == true
plotSegment = zeros(1,length(Mask.BlinkContinuous));
for is = 1:length(SamplesEnd)
    plotSegment(SamplesBeg(is):SamplesEnd(is)) = is;
end
    figure
    plot(plotSegment,'b');
    hold on;
    plot(Mask.BlinkContinuous,'r');
    legend({'Segment','Blink'});
end

end