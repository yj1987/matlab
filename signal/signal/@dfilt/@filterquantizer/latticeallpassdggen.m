function DGDF = latticeallpassdggen(q,Hd,coeffnames,doMapCoeffsToPorts,states)
%LATTICEALLPASSDGGEN Directed Graph generator for Discrete all pass
%lattice filter

%   Author(s): Honglei Chen
%   Copyright 1988-2004 The MathWorks, Inc.
%   $Revision: 1.1.6.5 $  $Date: 2009/07/14 04:02:37 $

error(nargchk(5,5,nargin,'struct'));

coefs = coefficients(Hd);
num=coefs{1};

% Get filter states and coefficient names
info.states = states;
info.coeffnames = coeffnames;
info.doMapCoeffsToPorts = doMapCoeffsToPorts;

% Represent the filter in terms of DG_Dfilt
DGDF = gen_DG_latticeallpass_stages(q,num,Hd,info);

% -------------------------------------------------------------------------
%
% gen_DG_dffir_stages: Generates the DG_DFILT representation
%   by constructing each "Stage" of the filter.
%
% -------------------------------------------------------------------------
function DGDF = gen_DG_latticeallpass_stages(q,num,H,info,hTar)

% Remove trailing zero-coefficients in polynomials:
num = num(1:max(find(num~=0)));

%determine the number of layers required to construct the filter
max_order = length(num);
info.nstages = max_order; 

% Create the header, body and the footer.
if max_order > 2
    Stg(1) = header(num,H,info,q);
    Stg(2) = body(num,H,info,q);
    Stg(3) = footer(num,H,info,q);
elseif max_order > 1
    Stg(1) = header(num,H,info,q);
    Stg(2) = footer(num,H,info,q);
elseif max_order == 1
    Stg = latticeallpassheader_order0(q,num,H,info);
else
    Stg = latticeempty(q,num,H,info);
end

% create demux
if info.doMapCoeffsToPorts && max_order>0
    % info.coeffnames is empty when it is header_order0 case, where the
    % coefficient of the Lattice is empty. Thus, no implementation for
    % demux.
    Stg(length(Stg)+1) = demux(q,H,max_order,info.coeffnames{1});    % demux for K
    Stg(length(Stg)+1) = demux(q,H,max_order,info.coeffnames{2});    % demux for K*
end

% make a DG_DFILT out of it.
% dg_dfilt is the bridge between the dfilt representation
% and directed graph representation

DGDF = filtgraph.dg_dfilt(Stg,'latticeallpass','rl');

% --------------------------------------------------------------
%
% head: Generate the conceptual header stage for Discrete FIR architecture
%
%   Returns a filtgraph.stage,
% --------------------------------------------------------------
function Head = header(num,H,info,q)

% Construct the first layer, structure specific
NL=filtgraph.nodelist(5);

NL.setnode(filtgraph.node('sum'),1);
NL.setnode(filtgraph.node('gain'),2);
NL.setnode(filtgraph.node('gain'),3);
NL.setnode(filtgraph.node('sum'),4);
NL.setnode(filtgraph.node('delay'),5);


% specify the block label
set(NL.nodes(1).block,'label','BodyQSum');
set(NL.nodes(2).block,'label','K');
set(NL.nodes(3).block,'label','K*');
set(NL.nodes(4).block,'label','BodyPSum');
set(NL.nodes(5).block,'label','BodyDelay');


% specify the relative position towards the grid
set(NL.nodes(1),'position',[0.3 0 0.3 0]);
set(NL.nodes(2),'position',[0.4 0.3 0.4 0.3]);
set(NL.nodes(3),'position',[0.4 0.7 0.4 0.7]);
set(NL.nodes(4),'position',[0.3 1 0.3 1]);
set(NL.nodes(5),'position',[0.7 1 0.7 1]);

% specify the orientation
set(NL.nodes(1).block,'orientation','right');
set(NL.nodes(2).block,'orientation','left');
set(NL.nodes(3).block,'orientation','left');
set(NL.nodes(4).block,'orientation','left');
set(NL.nodes(5).block,'orientation','left');

% Obtain the correct value for the gain block
pgain = NL.coeff2str(num(1),1);
qgain = NL.coeff2str(conj(num(1)),1);

% Specify coefficieint names
plabel = {}; qlabel = {};
if info.doMapCoeffsToPorts
    plabel{1} = sprintf('%s%d',info.coeffnames{1},1);
    qlabel{1} = sprintf('%s%d',info.coeffnames{2},1);
end

% store the useful information into blocks
mainparams(1)=filtgraph.indexparam(1,'|+-');
mainparams(2)=filtgraph.indexparam(2,pgain,plabel);
mainparams(3)=filtgraph.indexparam(3,qgain,qlabel);
mainparams(4)=filtgraph.indexparam(4,'++|');
mainparams(5)=filtgraph.indexparam(5,['1,' mat2str(info.states(1,:))]);

% Set extra parameters like fixed point attributes.  Also defines the extra
% blocks needed for fixed point model.  Connection among nodes will be
% generated in this function.  The interstage connection is also specified
% here.
[NL, NextIPorts, NextOPorts, mainparams]=latticeallpassheadconnect(q,NL,H,mainparams);

% Generate the stage.
Head = filtgraph.stage(NL,[],[],NextIPorts,NextOPorts,mainparams);

% --------------------------------------------------------------
%
% body: Generate the conceptual repeating body stage for the
% Direct Form I architecture
%   Returns a filtgraph.stage,
% --------------------------------------------------------------
function Body = body(num,H,info,q)

% Generating the repeating middle layers

NL=filtgraph.nodelist(5);

NL.setnode(filtgraph.node('sum'),1);
NL.setnode(filtgraph.node('gain'),2);
NL.setnode(filtgraph.node('gain'),3);
NL.setnode(filtgraph.node('sum'),4);
NL.setnode(filtgraph.node('delay'),5);


% specify the block label
set(NL.nodes(1).block,'label','BodyQSum');
set(NL.nodes(2).block,'label','K');
set(NL.nodes(3).block,'label','K*');
set(NL.nodes(4).block,'label','BodyPSum');
set(NL.nodes(5).block,'label','BodyDelay');


% specify the relative position towards the grid
set(NL.nodes(1),'position',[0.3 0 0.3 0]);
set(NL.nodes(2),'position',[0.4 0.3 0.4 0.3]);
set(NL.nodes(3),'position',[0.4 0.7 0.4 0.7]);
set(NL.nodes(4),'position',[0.3 1 0.3 1]);
set(NL.nodes(5),'position',[0.7 1 0.7 1]);

% specify the orientation
set(NL.nodes(1).block,'orientation','right');
set(NL.nodes(2).block,'orientation','left');
set(NL.nodes(3).block,'orientation','left');
set(NL.nodes(4).block,'orientation','left');
set(NL.nodes(5).block,'orientation','left');

% Main parameters of the blocks
pgain = {'0'}; qgain = {'0'};
for stage = 2:(info.nstages-1)
    pgain{stage-1} = NL.coeff2str(num,stage);
    qgain{stage-1} = NL.coeff2str(conj(num),stage);
      
    psum_str{stage-1}='|+-';  %left sum
    qsum_str{stage-1}='++|';
    
    delay_str{stage-1}=['1,' mat2str(info.states(stage,:))];

end

% Specify coefficieint names
plabel = {}; qlabel = {};
if info.doMapCoeffsToPorts
    for stage = 2:(info.nstages-1)
        plabel{stage-1} = sprintf('%s%d',info.coeffnames{1},stage);
        qlabel{stage-1} = sprintf('%s%d',info.coeffnames{2},stage);
    end
end

mainparams(1) = filtgraph.indexparam(1,psum_str);
mainparams(2) = filtgraph.indexparam(2,pgain,plabel);
mainparams(3) = filtgraph.indexparam(3,qgain,qlabel);
mainparams(4) = filtgraph.indexparam(4,qsum_str);
mainparams(5) = filtgraph.indexparam(5,delay_str);

% Set extra parameters like fixed point attributes.  Also defines the extra
% blocks needed for fixed point model.  Connection among nodes will be
% generated in this function.  The interstage connection is also specified
% here.
[NL, PrevIPorts, PrevOPorts, NextIPorts, NextOPorts, mainparams]=latticeallpassbodyconnect(q,NL,H,mainparams);

% The number of repetitions
bstages = info.nstages - 2;


Body = filtgraph.stage(NL, PrevIPorts, PrevOPorts,...
    NextIPorts, NextOPorts, mainparams, [], bstages);

% --------------------------------------------------------------
%
% footer: Generate the conceptual footer stage for Direct Form I
% architecture
%
%   Returns a filtgraph.stage,
% --------------------------------------------------------------
function Foot = footer(num,H,info,q)

% Generate the last layer of the structure.

NL=filtgraph.nodelist(5);

NL.setnode(filtgraph.node('sum'),1);
NL.setnode(filtgraph.node('gain'),2);
NL.setnode(filtgraph.node('gain'),3);
NL.setnode(filtgraph.node('sum'),4);
NL.setnode(filtgraph.node('delay'),5);


% specify the block label
set(NL.nodes(1).block,'label','BodyQSum');
set(NL.nodes(2).block,'label','K');
set(NL.nodes(3).block,'label','K*');
set(NL.nodes(4).block,'label','BodyPSum');
set(NL.nodes(5).block,'label','BodyDelay');


% specify the relative position towards the grid
set(NL.nodes(1),'position',[0.3 0 0.3 0]);
set(NL.nodes(2),'position',[0.4 0.3 0.4 0.3]);
set(NL.nodes(3),'position',[0.4 0.7 0.4 0.7]);
set(NL.nodes(4),'position',[0.3 1 0.3 1]);
set(NL.nodes(5),'position',[0.7 1 0.7 1]);

% specify the orientation
set(NL.nodes(1).block,'orientation','right');
set(NL.nodes(2).block,'orientation','left');
set(NL.nodes(3).block,'orientation','left');
set(NL.nodes(4).block,'orientation','left');
set(NL.nodes(5).block,'orientation','left');

% set up the parameter
pgain = {'0'}; qgain = {'0'};
pgain = NL.coeff2str(num,info.nstages); 
qgain = NL.coeff2str(conj(num),info.nstages);

% Specify coefficieint names
plabel = {}; qlabel = {};
if info.doMapCoeffsToPorts
    plabel{1} = sprintf('%s%d',info.coeffnames{1},info.nstages);
    qlabel{1} = sprintf('%s%d',info.coeffnames{2},info.nstages);
end

mainparams(1)=filtgraph.indexparam(1,'|+-');
mainparams(2)=filtgraph.indexparam(2,pgain,plabel);
mainparams(3)=filtgraph.indexparam(3,qgain,qlabel);
mainparams(4)=filtgraph.indexparam(4,'++|');
mainparams(5)=filtgraph.indexparam(5,['1,' mat2str(info.states(info.nstages,:))]);

% add input and output
NL.setnode(filtgraph.node('input'),6);
set(NL.nodes(6).block,'label','Input');
set(NL.nodes(6),'position',[-0.5 0 -0.5 0]);
set(NL.nodes(6).block,'orientation','right');
mainparams(6)=filtgraph.indexparam(6,{});

NL.setnode(filtgraph.node('output'),7);
set(NL.nodes(7).block,'label','Output');
set(NL.nodes(7),'position',[-0.5 1 -0.5 1]);
set(NL.nodes(7).block,'orientation','left');
mainparams(7)=filtgraph.indexparam(7,{});

[NL, PrevIPorts, PrevOPorts, mainparams]=latticeallpassfootconnect(q,NL,H,mainparams);

Foot = filtgraph.stage(NL, PrevIPorts, PrevOPorts, [], [], mainparams);
