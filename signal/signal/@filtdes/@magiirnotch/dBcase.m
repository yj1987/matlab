function dBcase(h,d)
%DBCASE Handle the dB case.
%
% This should be a private method.

%   Author(s): R. Losada
%   Copyright 1988-2003 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2004/04/13 00:10:27 $

convertmag(h,d,...
    {'Epass'},...
    {'Apass'},...
    {'pass'},...
    'todb');