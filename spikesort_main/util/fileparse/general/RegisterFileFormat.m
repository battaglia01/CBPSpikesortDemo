% Register a file formats that can be parsed by CBP.
%
% A registration consists of the following items:
% * File extension filter (i.e. "*.mat" or "*.prm;*.dat")
% * File format description
% * Handle to file read or /write function
% * A last argument which is either "import" or "export"
%
% Example: RegisterFileFormat("mat", "CBP file", @ParseCBPFile)

function RegisterFileFormat(ext, desc, funchandle, importorexport)
    global CBPInternals;

    assert(nargin == 4 && (importorexport == "import" || importorexport == "export"), ...
           "Must have four arguments, and last argument must be either " + ...
           "'import' or 'export'.");

   % Store files as a cell array of tuples in CBPInternals's "filetypes" object
   % This is an object with two subobjects: "import" and "export",
   % Each of these is a cell array of objects
   % If it doesn't exist, initialize
   if ~isfield(CBPInternals, "filetypes")
       CBPInternals.filetypes = [];
       CBPInternals.filetypes.import = {};
       CBPInternals.filetypes.export = {};
   end

   % create object to add to CBPInternals
   newfileobj = [];
   newfileobj.ext = char(ext);
   newfileobj.desc = char(desc);
   newfileobj.funchandle = funchandle;

   if importorexport == "import"
       CBPInternals.filetypes.import{end+1} = newfileobj;
   elseif importorexport == "export"
       CBPInternals.filetypes.export{end+1} = newfileobj;
   end
end
