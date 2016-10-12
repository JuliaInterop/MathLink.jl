# Constants - from mathlink.h

@enum(Pkt,
      PKT_ILLEGAL    =   0,
      PKT_CALL       =   7,
      PKT_EVALUATE   =  13,
      PKT_RETURN     =   3,
      PKT_INPUTNAME  =   8,
      PKT_ENTERTEXT  =  14,
      PKT_ENTEREXPR  =  15,
      PKT_OUTPUTNAME =   9,
      PKT_RETURNTEXT =   4,
      PKT_RETURNEXPR =  16,
      PKT_DISPLAY    =  11,
      PKT_DISPLAYEND =  12,
      PKT_MESSAGE    =   5,
      PKT_TEXT       =   2,
      PKT_INPUT      =   1,
      PKT_INPUTSTR   =  21,
      PKT_MENU       =   6,
      PKT_SYNTAX     =  10,
      PKT_SUSPEND    =  17,
      PKT_RESUME     =  18,
      PKT_BEGINDLG   =  19,
      PKT_ENDDLG     =  20,
      PKT_FIRSTUSER  = 128,
      PKT_LASTUSER   = 255)

@enum(Tkn,
  TKN_OLDINT  = 'I'%Cint,    # /* 73 Ox49 01001001 */ # /* integer leaf node */
  TKN_OLDREAL = 'R'%Cint,    # /* 82 Ox52 01010010 */ # /* real leaf node */

  TKN_FUNC    = 'F'%Cint,   # /* 70 Ox46 01000110 */ # /* non-leaf node */

  TKN_ERROR   = 0,
  TKN_STR     = '"'%Cint,         # /* 34 0x22 00100010 */
  TKN_SYM     = '\043'%Cint,      # /* 35 0x23 # 00100011 */ # /* octal here as hash requires a trigraph */

  TKN_REAL    = '*'%Cint,         # /* 42 0x2A 00101010 */
  TKN_INT     = '+'%Cint,         # /* 43 0x2B 00101011 */

  # /* The following defines are for internal use only */
  TKN_PCTEND  = ']'%Cint,     # /* at end of top level expression */
  TKN_END     = '\n'%Cint,
  TKN_AEND    = '\r'%Cint,
  TKN_SEND    = ','%Cint,

  TKN_CONT    = '\\'%Cint,
  TKN_ELEN    = ' '%Cint,

  TKN_NULL    = '.'%Cint,
  TKN_OLDSYM  = 'Y'%Cint,     # /* 89 0x59 01011001 */
  TKN_OLDSTR  = 'S'%Cint,     # /* 83 0x53 01010011 */

  TKN_PACKED  = 'P'%Cint,     # /* 80 0x50 01010000 */
  TKN_ARRAY   = 'A'%Cint,     # /* 65 0x41 01000001 */
  TKN_DIM     = 'D'%Cint)     # /* 68 0x44 01000100 */

@enum(Err,
  ERR_UNKNOWN         =   -1,
  ERR_OK              =    0,
  ERR_DEAD            =    1,
  ERR_GBAD            =    2,
  ERR_GSEQ            =    3,
  ERR_PBTK            =    4,
  ERR_PSEQ            =    5,
  ERR_PBIG            =    6,
  ERR_OVFL            =    7,
  ERR_MEM             =    8,
  ERR_ACCEPT          =    9,
  ERR_CONNECT         =   10,
  ERR_CLOSED          =   11,
  ERR_DEPTH           =   12,  # /* internal error */
  ERR_NODUPFCN        =   13,  # /* stream cannot be duplicated */

  ERR_NOACK           =   15,  # /* */
  ERR_NODATA          =   16,  # /* */
  ERR_NOTDELIVERED    =   17,  # /* */
  ERR_NOMSG           =   18,  # /* */
  ERR_FAILED          =   19,  # /* */

  ERR_GETENDEXPR      =   20,
  ERR_PUTENDPACKET    =   21, # /* unexpected call of MLEndPacket */
                               # /* currently atoms aren't
                               # * counted on the way out so this error is raised only when
                               # * MLEndPacket is called in the midst of an atom
                               # */
  ERR_NEXTPACKET      =   22,
  ERR_UNKNOWNPACKET   =   23,
  ERR_GETENDPACKET    =   24,
  ERR_ABORT           =   25,
  ERR_MORE            =   26, # /* internal error */
  ERR_NEWLIB          =   27,
  ERR_OLDLIB          =   28,
  ERR_BADPARAM        =   29,
  ERR_NOTIMPLEMENTED  =   30,


  ERR_INIT            =   32,
  ERR_ARGV            =   33,
  ERR_PROTOCOL        =   34,
  ERR_MODE            =   35,
  ERR_LAUNCH          =   36,
  ERR_LAUNCHAGAIN     =   37,
  ERR_LAUNCHSPACE     =   38,
  ERR_NOPARENT        =   39,
  ERR_NAMETAKEN       =   40,
  ERR_NOLISTEN        =   41,
  ERR_BADNAME         =   42,
  ERR_BADHOST         =   43,
  ERR_RESOURCE        =   44,  # /* a required resource was missing */
  ERR_LAUNCHFAILED    =   45,
  ERR_LAUNCHNAME      =   46,

  ERR_PDATABAD        =   47,
  ERR_PSCONVERT       =   48,
  ERR_GSCONVERT       =   49,
  ERR_NOTEXE          =   50,
  ERR_SYNCOBJECTMAKE  =   51,
  ERR_BACKOUT         =   52,

  ERR_TRACEON         =  996,  # /* */
  ERR_TRACEOFF        =  997,  # /* */
  ERR_DEBUG           =  998,  # /* */
  ERR_ASSERT          =  999,  # /* an internal assertion failed */
  ERR_USER            = 1000)  # /* start of user defined errors */
