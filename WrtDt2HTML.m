%* == function WrtDt2HTML.m : Takes stimuli/IRs stored in a structure BH and makes a set of plots to be arranged in an interactive html  
%** Written by James Traer - jtraer@mit.edu

function WrtDt2HTML(Dh,fNm,html_tmp,hNm,PltPrms,Flds,tmtpth)
if nargin<5;
    tmtpth=[];
end

%* == Inputs
%** BH  : a structure of audio files 
%** fNm : a filename to save the data under
fntsz=15;
if exist(tmtpth)==7
    Ds=GetTimit(tmtpth,'shuffle');
    Ds=Ds(1);
    for js=1:length(Ds);
        [TMT(js).s,TMT(js).fs]=audioread(Ds(js).name);
        audiowrite('tmt.wav',TMT(js).s,TMT(js).fs);
    end
else
    [TMT(1).s,TMT(1).fs]=audioread(tmt.wav);
end

%* == Preamble : make sure we have the requisite paths and search for flags
cfl=mfilename('fullpath'); %eval(sprintf('! ./Subroutines/ArchiveCode.sh %s.m',cfl));   
[stts,out]=unix(sprintf('grep -n HACK %s.m',cfl)); 
if length(out)>length(cfl)+153; 
    fprintf(2,'\n\nWARNING: check these hacks\n%s\n',out(length(cfl)+153:end)); 
    keyboard; 
end

%* == Log : Just started today (3rd-Oct)
%** TODO: when debugged search and replace variable names for more generic ones

%* ==== Crunch ====

%** Open the JSON file for writing
fid2=fopen(sprintf('%s/IRdata.json',fNm),'w')
fprintf(fid2,'var stimList = [\n')
%** => start loop over IRs (jIR)
for jIR=[1:length(Dh)]
    load(sprintf('%s/%s',Dh(jIR).PthStm,Dh(jIR).name)); 

    %** =>  make a folder to save images and audio to
    FldrNm=sprintf('%s/%s',fNm,H.Path); % where to copy files
    PthNm=sprintf('%s/%s',H.Path); % what to write in the html file (which will be a level below where we are now)
    eval(sprintf('! mkdir -p %s',FldrNm));

    %** => add a comma to separate indices in the JSON
    if jIR~=1;
        fprintf(fid2,',\n');
    end
    %** => open up a new element in the JSON
    fprintf(fid2,'{\n"blah":\t"blah"'); % the blahs put in an empty field so that hereafter all fields can be written in the same format

    %** => Plot special values 
    %*** => This should be fixed when we want to generalize this code to other stimuli
    %*** => T0
    fprintf(fid2,',\n"T0":\t%2.3f',median(H.RT60));
    %*** => path to audio
    %**** TODO update this to rescale volumes!!!
    tDh=dir(sprintf('%s/h_cal_%03d.wav',H.Path,length(H.ff)));
    t2Dh=dir(sprintf('%s/h_denoised_%03d.wav',H.Path,length(H.ff)));
    t3Dh=dir(sprintf('%s/h.wav',H.Path));
    if length(tDh)>0
        unix(sprintf('cp %s/%s %s/h.wav',H.Path,tDh(1).name,FldrNm));
        fprintf(fid2,',\n"sound":\t"%s/h.wav"',PthNm);
    elseif length(t2Dh)>0
        unix(sprintf('cp %s/%s %s/h.wav',H.Path,t2Dh(1).name,FldrNm));
        fprintf(fid2,',\n"sound":\t"%s/h.wav"',PthNm);
    elseif length(t3Dh)>0
        unix(sprintf('cp %s/%s %s/h.wav',H.Path,t3Dh(1).name,FldrNm));
        fprintf(fid2,',\n"sound":\t"%s/h.wav"',PthNm);
    end
    %*** => copy to a folder of just audio
    %eval(sprintf('! cp %s/%s IRMAudio/Audio/%s.wav',H.Path,tDh(1).name,H.Name));

    %*** => convolve with a TIMIT sentence
    if length(Ds)>0;
        [y,fy]=RIRcnv(TMT(1).s,TMT(1).fs,H.nh,H.fs,1);
        audiowrite(sprintf('%s/tmt1.wav',FldrNm),y,fy);
        fprintf(fid2,',\n"speech":\t"%s/tmt1.wav"',PthNm);
    end
    %%*** => write an image of the time series
    ici=pwd;
    if strcmp(ici(1:3),'/om')
        unix(sprintf('convert %s/IR.jpg %s/ts.png',H.Path,FldrNm));
    else
        unix(sprintf('sips -s format png %s/IR.jpg --out %s/ts.png',H.Path,FldrNm));
    end
    fprintf(fid2,',\n"TimeSeries":\t"%s/ts.png"',PthNm);

    %%*** => Copy photo 
    PhPth=H.Path;
    ndx=regexp(PhPth,'/');
    PhPth=PhPth(1:ndx(3));
    Dph=dir(sprintf('%s*.jpg',PhPth));
    for jph=1:length(Dph)
        if strcmp(ici(1:3),'/om')
            unix(sprintf('convert %s%s %sPhoto%d.png',PhPth,Dph(jph).name,FldrNm,jph));
        else
            unix(sprintf('sips -s format png %s%s --out %s/Photo%d.png',PhPth,Dph(jph).name,FldrNm,jph));
        end
    end
    fprintf(fid2,',\n"Photo":\t"%s/Photo1.png"',PthNm);

    %*** => write an image of the synthetic time series

    %%*** => plot C-gram
    if strcmp(ici(1:3),'/om')
        unix(sprintf('convert %s/Cgram.jpg %s/Cgrm.png',H.Path,FldrNm));
    else
        unix(sprintf('sips -s format png %s/Cgram.jpg --out %s/Cgrm.png',H.Path,FldrNm));
    end
    fprintf(fid2,',\n"Cgrm":\t"%s/Cgrm.png"',PthNm);
    
    %%*** => plot synthetic C-gram
    
    %%*** => plot RT60
    if strcmp(ici(1:3),'/om')
        unix(sprintf('convert %s/RT60.jpg %s/RT60.png',H.Path,FldrNm));
    else
        unix(sprintf('sips -s format png %s/RT60.jpg --out %s/RT60.png',H.Path,FldrNm));
    end
    fprintf(fid2,',\n"RT60":\t"%s/RT60.png"',PthNm);
    
    %%*** => plot spectrum
%    unix(sprintf('sips -s format png %s/IR_AttckSpc.jpg --out %s/Spc.png',H.Path,FldrNm));
%    fprintf(fid2,',\n"Spc":\t"%s/Spc.png"',PthNm);

    %** ==> loop over fields in structure and write them to the JSON file (jfld)
    for jf=1:length(Flds); 
        fld=Flds{jf};
        eval(sprintf('vl=H.%s;',fld));
        ndx=regexp(fld,'\.'); 
        if ~isempty(ndx);
            fld=fld(ndx(end)+1:end);
        end
        %*** ==> if it's a string write it
        if ischar(vl);
            fprintf(fid2,',\n"%s":\t"%s"',fld,vl);
        else
            if isstruct(vl)==0
                %*** ==> if it's a single number write it
                if length(vl)==1
                    fprintf(fid2,',\n"%s":\t%3.4f',fld,vl);
                end
            end
        end
    end
    %** ==< end-loop over fields in structure 

    %** => when all images are written close out the json structure
    fprintf(fid2,'\n}');
    %** => close all figures
    close all
end % for jIR
%** =< end-loop over folders of IRs (jIR)

% end the json file
fprintf(fid2,'\n]');
fclose(fid2)

%* == write the HTML file ==
unix(sprintf('cp %s tmp.html',html_tmp))
%** Delete current lines in template
[~,LnNdx]=unix(sprintf('sed -n ''/<img src="IRMAudio/='' tmp.html'));
LnNdx=str2num(LnNdx);
for jln=1:length(LnNdx);
    unix(sprintf('sed -i.bak -e ''%dd'' tmp.html',LnNdx(1)));
end
%** Write new ones
[~,LnNdx]=unix('sed -n ''/<div id="Stats">/='' tmp.html');
LnNdx=str2num(LnNdx);
for jPlt=1:length(PltPrms);
    Dplt=dir(sprintf('%s/%s/*.png',fNm,PltPrms{jPlt}));
    for jp=1:length(Dplt);
        unix(sprintf('awk ''NR==%d{print "    <img src=\\"%s/%s\\">"}7'' tmp.html >tmp2.html',LnNdx+1,PltPrms{jPlt},Dplt(jp).name)); 
        unix('mv tmp2.html tmp.html')
    end
end
unix(sprintf('mv tmp.html %s/%s.html',fNm,hNm))

%* == TODO: Save this code to a summary file
%eval(sprintf('! grep "%%\\*" %s.m > tmp.org',cfl))
%eval('! sed ''s/^ *//g'' < tmp.org > tmp2.org');  % remove whitespace
%eval('! sed ''s/^[ \\t]+//g'' < tmp2.org > tmp.org');  % remove tabs too
%eval(sprintf('! sed ''s/^.//'' tmp.org > %s.org',cfl))   % remove '%' so emacs can read the indenting
