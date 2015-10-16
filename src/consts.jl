# Constants - from mathlink.h

module Pkt
  const ILLEGAL    =   0

  const CALL       =   7
  const EVALUATE   =  13
  const RETURN     =   3

  const INPUTNAME  =   8
  const ENTERTEXT  =  14
  const ENTEREXPR  =  15
  const OUTPUTNAME =   9
  const RETURNTEXT =   4
  const RETURNEXPR =  16

  const DISPLAY    =  11
  const DISPLAYEND =  12

  const MESSAGE    =   5
  const TEXT       =   2

  const INPUT      =   1
  const INPUTSTR   =  21
  const MENU       =   6
  const SYNTAX     =  10

  const SUSPEND    =  17
  const RESUME     =  18

  const BEGINDLG   =  19
  const ENDDLG     =  20

  const FIRSTUSER  = 128
  const LASTUSER   = 255
end

module TK
  const OLDINT  =    'I'    # /* 73 Ox49 01001001 */ # /* integer leaf node */
  const OLDREAL =    'R'    # /* 82 Ox52 01010010 */ # /* real leaf node */

  const FUNC    = 'F'   # /* 70 Ox46 01000110 */ # /* non-leaf node */

  const ERROR   = Char(0)   # /* bad token */
  const ERR     = Char(0)   # /* bad token */

  const STR     = '"'         # /* 34 0x22 00100010 */
  const SYM     = '\043'      # /* 35 0x23 # 00100011 */ # /* octal here as hash requires a trigraph */

  const REAL    = '*'         # /* 42 0x2A 00101010 */
  const INT     = '+'         # /* 43 0x2B 00101011 */

  # /* The following defines are for internal use only */
  const PCTEND  = ']'     # /* at end of top level expression */
  const APCTEND = '\n'    # /* at end of top level expression */
  const END     = '\n'
  const AEND    = '\r'
  const SEND    = ','

  const CONT    = '\\'
  const ELEN    = ' '

  const NULL    = '.'
  const OLDSYM  = 'Y'     # /* 89 0x59 01011001 */
  const OLDSTR  = 'S'     # /* 83 0x53 01010011 */

  const PACKED  = 'P'     # /* 80 0x50 01010000 */
  const ARRAY   = 'A'     # /* 65 0x41 01000001 */
  const DIM     = 'D'     # /* 68 0x44 01000100 */
end

module ERR
  const UNKNOWN         =   -1
  const OK              =    0
  const DEAD            =    1
  const GBAD            =    2
  const GSEQ            =    3
  const PBTK            =    4
  const PSEQ            =    5
  const PBIG            =    6
  const OVFL            =    7
  const MEM             =    8
  const ACCEPT          =    9
  const CONNECT         =   10
  const CLOSED          =   11
  const DEPTH           =   12  # /* internal error */
  const NODUPFCN        =   13  # /* stream cannot be duplicated */

  const NOACK           =   15  # /* */
  const NODATA          =   16  # /* */
  const NOTDELIVERED    =   17  # /* */
  const NOMSG           =   18  # /* */
  const FAILED          =   19  # /* */

  const GETENDEXPR      =   20
  const PUTENDPACKET    =   21 # /* unexpected call of MLEndPacket */
                               # /* currently atoms aren't
                               # * counted on the way out so this error is raised only when
                               # * MLEndPacket is called in the midst of an atom
                               # */
  const NEXTPACKET      =   22
  const UNKNOWNPACKET   =   23
  const GETENDPACKET    =   24
  const ABORT           =   25
  const MORE            =   26 # /* internal error */
  const NEWLIB          =   27
  const OLDLIB          =   28
  const BADPARAM        =   29
  const NOTIMPLEMENTED  =   30


  const INIT            =   32
  const ARGV            =   33
  const PROTOCOL        =   34
  const MODE            =   35
  const LAUNCH          =   36
  const LAUNCHAGAIN     =   37
  const LAUNCHSPACE     =   38
  const NOPARENT        =   39
  const NAMETAKEN       =   40
  const NOLISTEN        =   41
  const BADNAME         =   42
  const BADHOST         =   43
  const RESOURCE        =   44  # /* a required resource was missing */
  const LAUNCHFAILED    =   45
  const LAUNCHNAME      =   46

  const PDATABAD        =   47
  const PSCONVERT       =   48
  const GSCONVERT       =   49
  const NOTEXE          =   50
  const SYNCOBJECTMAKE  =   51
  const BACKOUT         =   52

  const TRACEON         =  996  # /* */
  const TRACEOFF        =  997  # /* */
  const DEBUG           =  998  # /* */
  const ASSERT          =  999  # /* an internal assertion failed */
  const USER            = 1000  # /* start of user defined errors */
end
